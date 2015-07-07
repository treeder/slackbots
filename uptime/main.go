package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"time"

	"github.com/iron-io/iron_go/cache"
)

var c *cache.Cache
var client *PingdomClient
var slackClient *slackC

type Config struct {
	Username   string `json:"username"`
	Password   string `json:"password"`
	ApiKey     string `json:"api_key"`
	WebhookUrl string `json:"webhook_url"`
	MqIds      []int  `json:"mq"`
	WorkerIds  []int  `json:"worker"`
	OtherIds   []int  `json:"other"`
}

func main() {
	c = cache.New("uptime_bot")

	b, err := ioutil.ReadFile("config.json")

	if err != nil {
		fmt.Println(err)
		return
	}

	cfg := &Config{}
	err = json.Unmarshal(b, cfg)
	if err != nil {
		fmt.Println(err)
		return
	}

	client = &PingdomClient{
		Username: cfg.Username,
		Password: cfg.Password,
		ApiKey:   cfg.ApiKey,
	}

	slackClient = &slackC{
		url: cfg.WebhookUrl,
	}
	since := time.Now()
	mqUptimes := client.getUptimes(cfg.MqIds, since)
	workerUptimes := client.getUptimes(cfg.WorkerIds, since)
	otherUptimes := client.getUptimes(cfg.OtherIds, since)

	var attachments []Attachment
	attachments = append(attachments, buildReportsAttachment("IronMQ", mqUptimes))
	attachments = append(attachments, buildReportsAttachment("IronWorker", workerUptimes))
	attachments = append(attachments, buildReportsAttachment("Other", otherUptimes))

	slackClient.post("", attachments)
}

func buildReportsAttachment(name string, u UptimeReports) Attachment {
	var attachment Attachment
	if u.dailyUptime() >= .9998 {
		attachment.Color = "#2DD700"
	} else {
		attachment.Color = "#BD2121"
	}
	attachment.Title = name
	attachment.Fields = append(attachment.Fields, Field{
		Value: fmt.Sprintf("%.4f%% uptime over the last 24 hours (%s total downtime)", u.dailyUptime()*100, u.totalDailyDowntime()),
		Short: false,
	})
	attachment.Fields = append(attachment.Fields, Field{
		Title: "7 days",
		Value: fmt.Sprintf("%.4f%% (%s)", u.weeklyUptime()*100, u.totalWeeklyDowntime()),
		Short: true,
	})
	attachment.Fields = append(attachment.Fields, Field{
		Title: "1 month",
		Value: fmt.Sprintf("%.4f%% (%s)", u.monthlyUptime()*100, u.totalMonthlyDowntime()),
		Short: true,
	})
	return attachment
}
