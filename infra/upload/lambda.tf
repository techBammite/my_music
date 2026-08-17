# Archive du code du microservice Upload
data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/service_auxiliere/upload"
  output_path = "${path.module}/upload.zip"
  excludes    = ["upload.zip", ".terraform", "uploads"]
}

# Role IAM d'execution Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "mymusic-upload-lambda-exec-${local.suffix}"

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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy IAM d'acces S3 pour l'upload de media
resource "aws_iam_role_policy" "s3_access" {
  name = "mymusic-upload-s3-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:PutObjectAcl"
      ]
      Resource = "${aws_s3_bucket.media.arn}/*"
    }]
  })
}

# Fonction Lambda Node.js 20.x pour le service Upload (1024Mo RAM pour les gros MP3)
resource "aws_lambda_function" "upload" {
  filename         = data.archive_file.upload_zip.output_path
  function_name    = "mymusic-upload-service-${local.suffix}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.upload_zip.output_base64sha256
  timeout          = 30
  memory_size      = 1024

  environment {
    variables = {
      MEDIA_S3_BUCKET = aws_s3_bucket.media.id
      DB_HOST         = var.db_host
      DB_PORT         = var.db_port
      DB_USER         = var.db_user
      DB_PASSWORD     = var.db_password
      DB_NAME         = var.db_name
    }
  }

  tags = {
    Name = "mymusic-upload-lambda"
  }
}

# API Gateway HTTP API public pour multipart upload
resource "aws_apigatewayv2_api" "upload_gw" {
  name          = "mymusic-upload-api-${local.suffix}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.upload_gw.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.upload_gw.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.upload_gw.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.upload_gw.execution_arn}/*/*"
}
