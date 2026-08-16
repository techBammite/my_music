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
  function_name    = "mymusic-mail-service-${local.suffix}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

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

# Configuration de l'URL publique directe (Function URL)
resource "aws_lambda_function_url" "mail_url" {
  function_name      = aws_lambda_function.mail.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    expose_headers    = ["*"]
    max_age           = 86400
  }
}
