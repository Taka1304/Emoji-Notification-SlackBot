package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/slack-go/slack"
)

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var reqBody map[string]interface{}
	err := json.Unmarshal([]byte(request.Body), &reqBody)
	if err != nil {
		return events.APIGatewayProxyResponse{StatusCode: 400, Body: "Bad Request"}, nil
	}

	// URL検証イベントの処理
	if reqBody["type"] == "url_verification" {
		challenge, ok := reqBody["challenge"].(string)
		if !ok {
			return events.APIGatewayProxyResponse{StatusCode: 400, Body: "Challenge field missing"}, nil
		}
		return events.APIGatewayProxyResponse{StatusCode: 200, Body: challenge, Headers: map[string]string{"Content-Type": "text/plain"}}, nil
	}

	// イベントコールバックの処理
	if reqBody["type"] == "event_callback" {
		eventData, ok := reqBody["event"].(map[string]interface{})
		if !ok {
			return events.APIGatewayProxyResponse{StatusCode: 400, Body: "Event field missing"}, nil
		}
		eventType, ok := eventData["type"].(string)
		if !ok {
			return events.APIGatewayProxyResponse{StatusCode: 400, Body: "Event type missing"}, nil
		}

		if eventType == "emoji_changed" {
			handleEmojiChangedEvent(eventData)
		}

		return events.APIGatewayProxyResponse{StatusCode: 200, Body: "OK", Headers: map[string]string{"Content-Type": "text/plain"}}, nil
	}

	return events.APIGatewayProxyResponse{StatusCode: 200, Body: "Event type not handled"}, nil
}

func handleEmojiChangedEvent(eventData map[string]interface{}) {
	api := slack.New(os.Getenv("SLACK_BOT_TOKEN"))
	channelID := os.Getenv("CHANNEL_ID")
	name := eventData["name"].(string)
	text := fmt.Sprintf("新しい絵文字が追加されたのだ! \n`:%s:` :%s:", name, name)
	_, _, err := api.PostMessage(channelID, slack.MsgOptionText(text, false))
	if err != nil {
		fmt.Printf("Failed to post message: %v\n", err)
	}
}

func main() {
	lambda.Start(handleRequest)
}
