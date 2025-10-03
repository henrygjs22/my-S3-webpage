# Terraform 輸出值

output "s3_bucket_name" {
  description = "S3 bucket 名稱"
  value       = aws_s3_bucket.website_bucket.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website_bucket.arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket 域名"
  value       = aws_s3_bucket.website_bucket.bucket_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront 分配 ID"
  value       = aws_cloudfront_distribution.website_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront 分配 ARN"
  value       = aws_cloudfront_distribution.website_distribution.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront 域名"
  value       = aws_cloudfront_distribution.website_distribution.domain_name
}

output "website_url" {
  description = "網站 URL"
  value       = "https://${aws_cloudfront_distribution.website_distribution.domain_name}"
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "${aws_api_gateway_stage.main.invoke_url}/presigned-url"
}

output "aws_region" {
  description = "AWS 區域"
  value       = var.aws_region
}

output "deployment_instructions" {
  description = "部署說明"
  value = <<-EOT
    🚀 部署完成！
    
    網站 URL: https://${aws_cloudfront_distribution.website_distribution.domain_name}
    S3 Bucket: ${aws_s3_bucket.website_bucket.bucket}
    CloudFront ID: ${aws_cloudfront_distribution.website_distribution.id}
    API Gateway URL: ${aws_api_gateway_stage.main.invoke_url}/presigned-url
    
    注意事項：
    1. CloudFront 分配需要 10-15 分鐘才能完全部署
    2. 如果網站無法立即存取，請稍等片刻
    3. S3 bucket 已設定為 private，只能透過 CloudFront 存取
    4. 前端現在可以透過預簽名 URL 上傳到 S3
  EOT
}
