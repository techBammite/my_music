output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.mail.function_name
}

output "lambda_function_url" {
  description = "Public API Gateway HTTP Endpoint for Mail microservice"
  value       = aws_apigatewayv2_stage.default.invoke_url
}
