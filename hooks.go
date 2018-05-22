package main

import (
	"fmt"
	"github.com/phayes/hookserve/hookserve"
	"gopkg.in/tucnak/telebot.v1"
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

// handle webhook event
func handleEv(e hookserve.Event) {
	res, err := run("build", e.Repo, e.Branch)
	log.Println(res, err)
}

// send message
func send(msg string) {
	bot.SendMessage(chat, msg, nil)
}

// do the stuff
func run(args... string) (string, error) {
	// notify about starting build
	send(fmt.Sprintf("Task %v started #bashlapshaforever", args))
	// run cmd
	launch := append([]string{"./notify.sh"}, args...)
	out, err := exec.Command("/bin/bash", launch...).Output()
	// handle error
	if err != nil {
		send(fmt.Sprintf("Error! %v", err))
		return "", err
	}

	//error
	send("Result:\n" + string(out))
	return string(out), nil
}

func handleTelemsg(msg telebot.Message) {
	if !msg.IsPersonal() && (strings.HasPrefix(msg.Text, "/build ") || strings.HasPrefix(msg.Text, "/deploy ")) {
		if tok := strings.Fields(msg.Text); len(tok) >= 1 {
			args := append([]string{tok[0][1:]}, tok[1:]...)
			run(args...)
		}
	}
}
