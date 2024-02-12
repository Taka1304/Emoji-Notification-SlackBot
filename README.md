# Emoji-Notification-SlackBot

Notify specific channels that an emoji has been added

## requirements

### `.env` and `.tfvars`

| ENV | Description |
| -------- | -------- |
| SLACK_BOT_TOKEN |  Bot User OAuth Access Token<br />String beginning with `xoxb-` |
| CHANNEL_ID | For sending notifications |

## Debug

```
go run main.go
ngrok http http://localhost:3000
```

set SlackAPI endpoint

check verification