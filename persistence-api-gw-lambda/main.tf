provider "aws" {
  region = "us-east-1"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "buckets555-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AWSLambdaBasicExecutionRole
resource "aws_iam_role_policy_attachment" "basic_exec_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy to allow IAM user creation
resource "aws_iam_policy" "lambda_iam_user_creator" {
  name = "LambdaIAMUserCreator"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "iam:CreateUser"
      ],
      Resource = "*"
    }]
  })
}

# Attach custom policy to Lambda role
resource "aws_iam_policy_attachment" "attach_create_user_policy" {
  name       = "lambda-create-user-attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = aws_iam_policy.lambda_iam_user_creator.arn
}

# Archive the Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "buckets555" {
  function_name = "buckets555"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# HTTP API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "buckets555-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.buckets555.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /trigger"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.buckets555.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# outputs
output "lambda_function_name" {
  value = aws_lambda_function.buckets555.function_name
}
output "api_gateway_url" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/trigger"
}