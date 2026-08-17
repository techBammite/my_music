output "lambda_function_url" {
  description = "Public API Gateway HTTP Endpoint URL for Moment Lambda"
  value       = aws_apigatewayv2_stage.default.invoke_url
}
