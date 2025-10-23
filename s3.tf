# S3 相關資源配置

# 隨機字串用於 S3 bucket 名稱唯一性
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket 用於存放靜態網站
resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.bucket_name_prefix}-${random_string.bucket_suffix.result}"

  force_destroy = true  # 允許 Terraform 刪除非空 bucket

  tags = local.common_tags
}

# S3 Bucket 擁有權控制
resource "aws_s3_bucket_ownership_controls" "website_bucket_ownership" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket 版本控制
resource "aws_s3_bucket_versioning" "website_bucket_versioning" {
  bucket = aws_s3_bucket.website_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket 伺服器端加密
resource "aws_s3_bucket_server_side_encryption_configuration" "website_bucket_encryption" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket CORS 配置
resource "aws_s3_bucket_cors_configuration" "website_bucket_cors" {
  bucket = aws_s3_bucket.website_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET", "HEAD", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag", "x-amz-request-id"]
    max_age_seconds = 3000
  }
}

# S3 Bucket 公共存取阻擋設定（確保 private）
resource "aws_s3_bucket_public_access_block" "website_bucket_pab" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = false  # 允許 bucket 政策，用於預簽名 URL 上傳
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket 政策 - 只允許 CloudFront 存取
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
          }
        }
      },
      {
        Sid    = "AllowPresignedUrlUploads"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/uploads/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.website_bucket_pab,
    aws_cloudfront_distribution.website_distribution
  ]
}

# 上傳 index.js (帶字串替換)
resource "aws_s3_object" "index_js" {
  bucket  = aws_s3_bucket.website_bucket.id
  key     = "index.js"
  content = replace(file("${path.module}/src/index.js"), "REPLACE_WITH_API_GATEWAY_URL", "${aws_api_gateway_stage.main.invoke_url}/presigned-url")
  etag    = md5(replace(file("${path.module}/src/index.js"), "REPLACE_WITH_API_GATEWAY_URL", "${aws_api_gateway_stage.main.invoke_url}/presigned-url"))

  content_type = "application/javascript; charset=utf-8"
}

# 上傳其他靜態網站檔案到 S3
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/src", "*.{html,css}")

  bucket = aws_s3_bucket.website_bucket.id
  key    = each.value
  source = "${path.module}/src/${each.value}"
  etag   = filemd5("${path.module}/src/${each.value}")

  content_type = each.value == "index.html" ? "text/html; charset=utf-8" : "text/css; charset=utf-8"
}
