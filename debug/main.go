package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
		"os"

    "github.com/joho/godotenv"
    "github.com/slack-go/slack"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	http.HandleFunc("/slack/events", func(w http.ResponseWriter, r *http.Request) {
    var reqBody map[string]interface{}
    err := json.NewDecoder(r.Body).Decode(&reqBody)
    if err != nil {
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
    }

    // URL検証イベントの処理
    if reqBody["type"] == "url_verification" {
			challenge := reqBody["challenge"].(string)
			w.Header().Set("Content-Type", "text/plain")
			w.Write([]byte(challenge))
			return
    }

		// イベントコールバックの処理
		if reqBody["type"] == "event_callback" {
			eventData := reqBody["event"].(map[string]interface{})
			eventType := eventData["type"].(string)
			if eventType == "emoji_changed" {
				api := slack.New(os.Getenv("SLACK_BOT_TOKEN"))
				channelID := os.Getenv("CHANNEL_ID")
				name := eventData["name"].(string)
				text := fmt.Sprintf("新しい絵文字が追加されました! \n`:%s:` :%s:", name, name)
				_, _, err := api.PostMessage(channelID, slack.MsgOptionText(text, false))
				if err != nil {
					log.Printf("Failed to post message: %v", err)
				}
			}
			w.Header().Set("Content-Type", "text/plain")
			w.Write([]byte("OK"))
		}
	})

	fmt.Println("Server listening")
	http.ListenAndServe(":3000", nil)
}
