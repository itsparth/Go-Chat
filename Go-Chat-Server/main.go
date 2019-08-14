package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"
)

//Storing messages in server
type Message struct {
	Id      int
	Name    string
	Message string
}

type user struct {
	Name  string
	Token string
	Time  time.Time
}

//Constants
var messages []Message
var usersList []user

const ServerDefaultName = "Server"

var mux sync.Mutex

//Gets the message to be sent to the user after lastMessageId
func getMessages(lastMessageId int) []Message {
	//No new messages check
	if lastMessageId == 0 {
		return messages
	}
	if len(messages) <= lastMessageId || lastMessageId < 0 {
		return nil
	}
	return messages[lastMessageId:]
}

func handleGetRequest(w http.ResponseWriter, r *http.Request) {
	s := strings.Split(r.URL.Path, "/")[2:]
	if len(s) >= 2 {
		name := ""

		mux.Lock()
		for i, u := range usersList {
			if s[0] == u.Token {
				name = u.Name
				usersList[i].Time = time.Now()
				break
			}
		}
		mux.Unlock()
		if name == "" {
			w.Write([]byte("Token Expired"))
			return
		}

		messageId, err := strconv.Atoi(s[1])

		if err != nil {
			fmt.Println(err)
			return
		}
		response := getMessages(messageId)

		if response == nil {
			w.Write([]byte(""))
			return
		}
		jsonResp, err := json.Marshal(response)
		if err != nil {
			fmt.Println(err)
			return
		}
		w.Write([]byte(jsonResp))
	}
}
func handlePostRequest(w http.ResponseWriter, r *http.Request) {
	s := strings.Split(r.URL.Path, "/")[2:]
	if len(s) == 0 {
		return
	}
	name := ""
	for _, u := range usersList {
		if s[0] == u.Token {
			name = u.Name
			break
		}
	}
	if name == "" {
		w.Write([]byte("Token Expired"))
		return
	}
	decoder := json.NewDecoder(r.Body)
	var t Message
	err := decoder.Decode(&t)
	if err != nil {
		fmt.Println("Error")
		fmt.Println(err)
		return
	}
	t.Id = len(messages) + 1
	t.Name = name

	mux.Lock()
	messages = append(messages, t)
	mux.Unlock()
}

func handleJoinRequest(w http.ResponseWriter, r *http.Request) {
	s := strings.Split(r.URL.Path, "/")[2:]

	if len(s) != 0 {
		name := s[0]
		if name == "Server" {
			w.Write([]byte(""))
			return
		}
		mux.Lock()
		for _, ruser := range usersList {
			if name == ruser.Name {
				w.Write([]byte(""))
				mux.Unlock()
				return
			}
		}
		mux.Unlock()

		u := user{
			Name:  name,
			Token: String(15),
			Time:  time.Now(),
		}
		m := Message{
			Id:      len(messages) + 1,
			Name:    ServerDefaultName,
			Message: name + " has joined the server. Have Fun.",
		}
		mux.Lock()
		usersList = append(usersList, u)
		messages = append(messages, m)
		mux.Unlock()
		w.Write([]byte(u.Token))
	}
}
func handleDisconnect() {
	for {
		mux.Lock()
		for i := 0; i < len(usersList); i++ {
			u := usersList[i]
			if u.Time.Add(time.Second * 5).Before(time.Now()) {
				m := Message{
					Id:      len(messages) + 1,
					Name:    ServerDefaultName,
					Message: u.Name + " has left the server. Good Bye.",
				}

				messages = append(messages, m)
				usersList[len(usersList)-1], usersList[i] = usersList[i], usersList[len(usersList)-1]
				usersList = usersList[:len(usersList)-1]
				i--
			}
		}
		mux.Unlock()
		<-time.After(5 * time.Second)
	}
}

//Manages the get and post requests
func manageChatRequest(w http.ResponseWriter, r *http.Request) {
	//Returns messages if request is get and add to messages if request is post
	if r.Method == "GET" {
		handleGetRequest(w, r)

	} else if r.Method == "POST" {
		handlePostRequest(w, r)

	} else {
		http.Error(w, "Invalid request method.", 405)
	}

}
func manageJoinRequest(w http.ResponseWriter, r *http.Request) {
	//Returns messages if request is get and add to messages if request is post
	if r.Method == "GET" {
		handleJoinRequest(w, r)
	} else {
		http.Error(w, "Invalid request method.", 405)
	}

}

func main() {
	//Starting server
	http.HandleFunc("/join/", manageJoinRequest)
	http.HandleFunc("/chat/", manageChatRequest)

	go handleDisconnect()

	if err := http.ListenAndServe(":8080", nil); err != nil {
		panic(err)
	}
}

const charset = "abcdefghijklmnopqrstuvwxyz" +
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var seededRand *rand.Rand = rand.New(
	rand.NewSource(time.Now().UnixNano()))

func StringWithCharset(length int, charset string) string {
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[seededRand.Intn(len(charset))]
	}
	return string(b)
}

func String(length int) string {
	return StringWithCharset(length, charset)
}
