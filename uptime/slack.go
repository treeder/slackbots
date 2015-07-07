package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
)

type slackC struct {
	url string
}

type slackPayload struct {
	Text        string       `json:"text"`
	Attachments []Attachment `json:"attachments"`
}

type Attachment struct {
	Fallback   string  `json:"fallback"`
	Color      string  `json:"color"`
	Pretext    string  `json:"pretext"`
	AuthorName string  `json:"author_name"`
	AuthorLink string  `json:"author_link"`
	AuthorIcon string  `json:"author_icon"`
	Title      string  `json:"title"`
	TitleLink  string  `json:"title_link"`
	Text       string  `json:"text"`
	Fields     []Field `json:"fields"`
	ImageURL   string  `json:"image_url"`
	ThumbURL   string  `json:"thumb_url"`
}
type Field struct {
	Title string `json:"title"`
	Value string `json:"value"`
	Short bool   `json:"short"`
}

func (s *slackC) post(text string, attachments []Attachment) {
	payload := slackPayload{Text: text, Attachments: attachments}
	b, err := json.Marshal(payload)
	if err != nil {
		fmt.Println(err)
		return
	}
	buf := bytes.NewBuffer(b)
	_, err = http.Post(s.url, "application/json", buf)
	if err != nil {
		fmt.Println(err)
		return
	}
}
