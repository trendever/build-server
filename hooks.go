package main

import (
	"fmt"
	"github.com/phayes/hookserve/hookserve"
	"github.com/tucnak/telebot"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"
)

// well, this part sucks
type chatDestination string

func (dst chatDestination) Destination() string {
	return string(dst)
}

var bot *telebot.Bot
var chat chatDestination

func main() {

	// github init part
	server := hookserve.NewServer()
	server.Port = 8090
	server.Secret = os.Getenv("SECRET")
	server.GoListenAndServe()

	// telebot init part
	var err error
	bot, err = telebot.NewBot(os.Getenv("SECRET_TOKEN"))
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}

	chat = chatDestination(os.Getenv("CHAT"))
	messages := make(chan telebot.Message)
	bot.Listen(messages, 1*time.Second)

	// webhook events
	go func() {
		for event := range server.Events {
			go handleEv(event)
		}
	}()

	// telebot events
	for message := range messages {
		go handleTelemsg(message)
	}

}

func handleEv(e hookserve.Event) {
	res, err := run(e.Repo, e.Branch)
	log.Println(res, err)
}

func send(msg string) {
	bot.SendMessage(chat, msg, nil)
}

func run(repo, branch string) (string, error) {
	send(fmt.Sprintf("Build %v_%v started", branch, repo))
	out, err := exec.Command("/bin/bash", "./notify.sh", repo, branch).Output()
	if err != nil {
		send(fmt.Sprintf("Error! %v", err))
		return "", err
	}

	send("Result:\n" + string(out))
	return string(out), nil
}

func handleTelemsg(msg telebot.Message) {
	if !msg.IsPersonal() && strings.HasPrefix(msg.Text, "/build") {
		if tok := strings.Fields(msg.Text); len(tok) == 3 {
			run(tok[1], tok[2])
		}
	}
}
