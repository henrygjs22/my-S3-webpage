# Terraform 變數定義

variable "aws_region" {
  description = "AWS 區域"
  type        = string
  default     = "ap-east-2"
}

variable "environment" {
  description = "環境名稱"
  type        = string
  default     = "production"
}

variable "bucket_name_prefix" {
  description = "S3 bucket 名稱前綴"
  type        = string
  default     = "static-website"
}

variable "cloudfront_price_class" {
  description = "CloudFront 價格等級"
  type        = string
  default     = "PriceClass_100"  # 只使用北美和歐洲的邊緣位置
  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200", 
      "PriceClass_100"
    ], var.cloudfront_price_class)
    error_message = "CloudFront 價格等級必須是 PriceClass_All、PriceClass_200 或 PriceClass_100。"
  }
}

variable "discord_webhook_url" {
  description = "Discord Webhook URL 用於 S3 事件通知"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^https://discord\\.com/api/webhooks/", var.discord_webhook_url))
    error_message = "Discord Webhook URL 必須是有效的 Discord webhook URL。"
  }
}