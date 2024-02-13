################################
# Variables
################################

variable aws_profile {}
variable aws_region {}
variable resource_prefix {}
variable SLACK_BOT_TOKEN {}
variable CHANNEL_ID {}

################################
# LambdaにアタッチするIAM Role
################################

resource "aws_iam_role" "lambda_role" {
  name               = "${var.resource_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

################################
# API GatewayにアタッチするIAM Role
################################

resource "aws_iam_role" "api_gateway_role" {
  name               = "${var.resource_prefix}-apigateway-role"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy_logs" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy_lambda" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

################################
# Lambda
################################

resource "aws_lambda_function" "lambda" {
  function_name    = "${var.resource_prefix}"
  filename         = "./lambda/archive/sample.zip"
  role             = aws_iam_role.lambda_role.arn
  handler          = "sample.exe"
  runtime          = "provided.al2"
  environment {
    variables = {
      SLACK_BOT_TOKEN = var.SLACK_BOT_TOKEN
      CHANNEL_ID      = var.CHANNEL_ID
    }
  }
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "null_resource" "default" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    # Windows
    environment = {
      GOOS = "linux"
      GOARCH = "amd64"
    }
    command = "cd ./lambda/cmd/ && go build -o ../build/bootstrap main.go"
  }
}
 
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "./lambda/build/bootstrap"
  output_path = "./lambda/archive/sample.zip"
 
  depends_on = [null_resource.default]
}

resource "aws_lambda_permission" "api_gateway_invoke_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

################################
# API Gateway
################################

resource "aws_apigatewayv2_api" "api" {
  name = "${var.resource_prefix}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
  # credentials_arn = aws_iam_role.api_gateway_role.arn
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


resource "aws_apigatewayv2_deployment" "api_deployment" {
  api_id      = aws_apigatewayv2_api.api.id
  # デプロイメントのトリガーとしてルートの変更を利用
  depends_on = [aws_apigatewayv2_route.lambda_route]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id        = aws_apigatewayv2_api.api.id
  name          = "$default"
  deployment_id = aws_apigatewayv2_deployment.api_deployment.id
}


data "aws_iam_policy_document" "api_gateway_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "*"
      identifiers = ["*"]
    }
    actions   = ["execute-api:Invoke"]
    resources = ["${aws_apigatewayv2_api.api.execution_arn}/*"]
  }
}

output "api_endpoint" {
  description = "The endpoint URL of the API Gateway"
  value       = aws_apigatewayv2_api.api.api_endpoint
}
