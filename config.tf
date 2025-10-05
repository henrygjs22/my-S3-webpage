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
