# S3 靜態網站 + CloudFront CDN 部署配置
# 使用 Terraform 管理 AWS 資源

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}

# 設定 AWS Provider
provider "aws" {
  region = var.aws_region
}

# 本地變數
locals {
  common_tags = {
    Project     = "S3-Static-Website"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 隨機字串用於 S3 bucket 名稱唯一性
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket 用於存放靜態網站
resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.bucket_name_prefix}-${random_string.bucket_suffix.result}"

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
    allowed_origins = [
      "*",
      "https://${aws_cloudfront_distribution.website_distribution.domain_name}",
      "https://d2wgdch25moel1.cloudfront.net"
    ]
    expose_headers  = ["ETag", "x-amz-request-id"]
    max_age_seconds = 3000
  }
}

# S3 Bucket 公共存取阻擋設定（確保 private）
resource "aws_s3_bucket_public_access_block" "website_bucket_pab" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
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
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.website_bucket_pab,
    aws_cloudfront_distribution.website_distribution
  ]
}

# 上傳靜態網站檔案到 S3
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/src", "*.{html,js,css}")

  bucket = aws_s3_bucket.website_bucket.id
  key    = each.value
  source = "${path.module}/src/${each.value}"
  etag   = filemd5("${path.module}/src/${each.value}")

  content_type = each.value == "index.html" ? "text/html; charset=utf-8" : (each.value == "index.js" ? "application/javascript; charset=utf-8" : "text/css; charset=utf-8")
}

# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name                              = "${var.bucket_name_prefix}-oac"
  description                       = "OAC for S3 website bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront 分配
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
    origin_id                = "S3-${aws_s3_bucket.website_bucket.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for S3 static website"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # 快取行為設定
  ordered_cache_behavior {
    path_pattern     = "*.js"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

# ==================== Lambda 函數相關資源 ====================

# Lambda 函數的 IAM 角色
resource "aws_iam_role" "lambda_role" {
  name = "${var.bucket_name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Lambda 函數的 IAM 政策
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.bucket_name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# 創建 Lambda 函數的部署包
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/s3_discord_notification.py"
  output_path = "${path.module}/lambda/s3_discord_notification.zip"
}

# Lambda 函數
resource "aws_lambda_function" "s3_discord_notification" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.bucket_name_prefix}-s3-discord-notification"
  role            = aws_iam_role.lambda_role.arn
  handler         = "s3_discord_notification.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.website_bucket.id
    }
  }

  tags = local.common_tags
}

# S3 事件通知許可
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_discord_notification.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.website_bucket.arn
}

# S3 事件通知配置
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.website_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_discord_notification.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_discord_notification.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpeg"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_discord_notification.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".png"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_discord_notification.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".gif"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# ==================== 預簽名 URL Lambda 函數 ====================

# 生成預簽名 URL 的 Lambda 函數
resource "aws_lambda_function" "presigned_url_generator" {
  filename         = data.archive_file.presigned_url_lambda_zip.output_path
  function_name    = "${var.bucket_name_prefix}-presigned-url-generator"
  role            = aws_iam_role.presigned_url_lambda_role.arn
  handler         = "presigned_url_generator.lambda_handler"
  source_code_hash = data.archive_file.presigned_url_lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.website_bucket.id
    }
  }

  tags = local.common_tags
}

# 預簽名 URL Lambda 的 IAM 角色
resource "aws_iam_role" "presigned_url_lambda_role" {
  name = "${var.bucket_name_prefix}-presigned-url-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# 預簽名 URL Lambda 的 IAM 政策
resource "aws_iam_role_policy" "presigned_url_lambda_policy" {
  name = "${var.bucket_name_prefix}-presigned-url-lambda-policy"
  role = aws_iam_role.presigned_url_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# 創建預簽名 URL Lambda 的部署包
data "archive_file" "presigned_url_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/presigned_url_generator.py"
  output_path = "${path.module}/lambda/presigned_url_generator.zip"
}

# API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.bucket_name_prefix}-api"
  description = "API for generating presigned URLs"

  tags = local.common_tags
}

# API Gateway 資源
resource "aws_api_gateway_resource" "presigned_url" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "presigned-url"
}

# API Gateway 方法
resource "aws_api_gateway_method" "presigned_url_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.presigned_url.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway OPTIONS 方法 (CORS)
resource "aws_api_gateway_method" "presigned_url_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.presigned_url.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# API Gateway OPTIONS 整合
resource "aws_api_gateway_integration" "presigned_url_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.presigned_url.id
  http_method = aws_api_gateway_method.presigned_url_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# API Gateway OPTIONS 方法回應
resource "aws_api_gateway_method_response" "presigned_url_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.presigned_url.id
  http_method = aws_api_gateway_method.presigned_url_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# API Gateway OPTIONS 整合回應
resource "aws_api_gateway_integration_response" "presigned_url_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.presigned_url.id
  http_method = aws_api_gateway_method.presigned_url_options.http_method
  status_code = aws_api_gateway_method_response.presigned_url_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# API Gateway 整合
resource "aws_api_gateway_integration" "presigned_url_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.presigned_url.id
  http_method = aws_api_gateway_method.presigned_url_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.presigned_url_generator.invoke_arn
}

# Lambda 許可
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url_generator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Gateway 部署
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.presigned_url_integration,
    aws_api_gateway_integration.presigned_url_options_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"
}
