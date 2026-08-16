output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.mail.function_name
}

output "lambda_function_url" {
  description = "Public Function URL of the Mail Lambda microservice"
  value       = aws_lambda_function_url.mail_url.function_url
}
