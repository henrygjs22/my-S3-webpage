# Lambda 函數相關資源配置

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
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
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
