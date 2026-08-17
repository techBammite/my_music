# Archive du code du microservice Moment
data "archive_file" "moment_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/service_auxiliere/moment"
  output_path = "${path.module}/moment.zip"
  excludes    = ["moment.zip", ".terraform"]
}

# Role IAM d'execution Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "mymusic-moment-lambda-exec-${local.suffix}"

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

# Fonction Lambda Node.js 20.x pour le service Moment
resource "aws_lambda_function" "moment" {
  filename         = data.archive_file.moment_zip.output_path
  function_name    = "mymusic-moment-service-${local.suffix}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.moment_zip.output_base64sha256
  timeout          = 10
  memory_size      = 128

  tags = {
    Name = "mymusic-moment-lambda"
  }
}

# API Gateway HTTP API public
resource "aws_apigatewayv2_api" "moment_gw" {
  name          = "mymusic-moment-api-${local.suffix}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.moment_gw.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.moment_gw.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.moment.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.moment_gw.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.moment.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.moment_gw.execution_arn}/*/*"
}
