output "lambda_function_url" {
  description = "Public API Gateway HTTP Endpoint URL for Upload Lambda"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "media_s3_bucket_name" {
  description = "S3 Bucket Name for Media Storage"
  value       = aws_s3_bucket.media.id
}
