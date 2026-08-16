# Role IAM pour l'execution de la fonction Lambda Mail
resource "aws_iam_role" "lambda_exec" {
  name = "mymusic-mail-lambda-role-${local.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach basic execution policy (CloudWatch logs)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Fonction Lambda pour le Microservice Mail
resource "aws_lambda_function" "mail" {
  function_name = "mymusic-mail-service-${local.suffix}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 256

  filename         = "${path.module}/mail.zip"
  source_code_hash = fileexists("${path.module}/mail.zip") ? filebase64sha256("${path.module}/mail.zip") : null

  environment {
    variables = {
      NODE_ENV        = "production"
      SMTP_HOST       = var.smtp_host
      SMTP_PORT       = var.smtp_port
      SMTP_USERNAME   = var.smtp_username
      SMTP_PASSWORD   = var.smtp_password
      SMTP_FROM_EMAIL = var.smtp_from_email
      SMTP_FROM_NAME  = var.smtp_from_name
    }
  }

  tags = {
    Name = "mymusic-mail-lambda"
  }
}

# API Gateway HTTP API (Solution infaillible et 100% publique sans restriction de compte)
resource "aws_apigatewayv2_api" "mail_api" {
  name          = "mymusic-mail-api-${local.suffix}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

# Stage par defaut $default avec auto-deploy
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.mail_api.id
  name        = "$default"
  auto_deploy = true
}

# Integration API Gateway -> Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.mail_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.mail.invoke_arn
}

# Route par defaut (Redirige TOUTES les requetes vers Lambda)
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.mail_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Permission IAM autorisant API Gateway a invoquer la fonction Lambda
resource "aws_lambda_permission" "apigw_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mail.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.mail_api.execution_arn}/*/*"
}
