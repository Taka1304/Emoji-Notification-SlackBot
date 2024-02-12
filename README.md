# Emoji-Notification-SlackBot

Notify specific channels that an emoji has been added

## requirements

### `.env`

| ENV | Description |
| -------- | -------- |
| SLACK_BOT_TOKEN |  Bot User OAuth Access Token<br />String beginning with `xoxb-` |
| CHANNEL_ID | For sending notifications |
| LAMBDA_ARN | ARN of AWS Lambda |

## Debug

```
cd debug
go run main.go
ngrok http http://localhost:3000
```

- Set SlackAPI endpoint
- Check verification

## Deploy

### AWS Lambda

1. Set "Emoji-Notification-SlackBot" as the FunctionName
1. Set "Amazon Linux 2" as the runtime

### AWS API Gateway

1. Create HTTP API
1. Create Route, POST method
1. Integrate Lambda Function
1. Copy URL
1. Set SlackAPI endpoint

### (AWS CloudWatch)
Not required, but useful for debugging

### deploy command

```
terraform init
terraform apply -var-file .env
```