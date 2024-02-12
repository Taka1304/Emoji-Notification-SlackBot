resource "aws_lambda_function" "lambda" {
  function_name    = "Emoji-Notification-SlackBot"
  filename         = "./lambda/archive/sample.zip"
  role             = var.LAMBDA_ARN
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