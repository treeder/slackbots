package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"sync"
	"time"
)

const host = "https://api.pingdom.com/api/2.0/"

type PingdomClient struct {
	Username string
	Password string
	ApiKey   string
	client   http.Client
}

type Check struct {
	Id     int    `json:"id"`
	Name   string `json:"name"`
	Status string `json:"status"`
}

func (c *PingdomClient) Get(endpoint string) (*http.Response, error) {
	req, err := http.NewRequest("GET", host+endpoint, nil)
	if err != nil {
		return nil, err
	}
	req.SetBasicAuth(c.Username, c.Password)
	req.Header.Set("App-Key", c.ApiKey)
	res, err := c.client.Do(req)
	return res, err
}

func (c *PingdomClient) getChecks() ([]Check, error) {
	res, err := c.Get("checks/")
	if err != nil {
		return nil, err
	}

	b, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}

	checkList := struct {
		Checks []Check `json:"checks"`
	}{}
	err = json.Unmarshal(b, &checkList)
	if err != nil {
		return nil, err
	}
	return checkList.Checks, err
}

func (c *PingdomClient) getCheckById(id int) (Check, error) {
	endpoint := fmt.Sprintf("checks/%d", id)
	res, err := c.Get(endpoint)
	if err != nil || res.StatusCode != 200 {
		return Check{}, err
	}

	b, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return Check{}, err
	}

	check := struct {
		Check Check `json:"check"`
	}{}
	err = json.Unmarshal(b, &check)
	if err != nil {
		return Check{}, err
	}
	return check.Check, err
}

func (c *PingdomClient) getUptime(check *Check, from time.Time) (*Status, error) {
	fromString := strconv.FormatInt(from.Unix(), 10)
	endpoint := fmt.Sprintf("summary.average/%d?includeuptime=true&from=%s", check.Id, fromString)
	res, err := c.Get(endpoint)
	if err != nil || res.StatusCode != 200 {
		return &Status{}, err
	}

	b, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return &Status{}, err
	}
	s := struct {
		S struct {
			Status Status `json:"status"`
		} `json:"summary"`
	}{}
	err = json.Unmarshal(b, &s)
	if err != nil {
		fmt.Println(err)
	}
	return &s.S.Status, err
}

func (c *PingdomClient) getUptimes(alertIds []int, since time.Time) UptimeReports {
	var checks []*Check
	for _, id := range alertIds {
		check, err := c.getCheckById(id)
		if err != nil {
			fmt.Println(err)
		} else {
			checks = append(checks, &check)
		}
	}

	var uptimeReports UptimeReports
	for _, check := range checks {
		// We don't want anything thats paused
		if check.Status != "paused" && check.Status != "unknown" {
			u := &UptimeReport{
				Name: check.Name,
				Id:   check.Id,
			}
			if ur, err := client.getUptime(check, since.AddDate(0, 0, -1)); err == nil {
				u.DayAgo = ur
			}
			if ur, err := client.getUptime(check, since.AddDate(0, 0, -7)); err == nil {
				u.WeekAgo = ur
			}
			if ur, err := client.getUptime(check, since.AddDate(0, -1, 0)); err == nil {
				u.MonthAgo = ur
			}
			uptimeReports = append(uptimeReports, u)
		}
	}
	return uptimeReports
}

type UptimeReport struct {
	Id       int    `json:"id"`
	Name     string `json:"name"`
	DayAgo   *Status
	WeekAgo  *Status
	MonthAgo *Status
}

type Status struct {
	Totalup      int64 `json:"totalup"`
	Totaldown    int64 `json:"totaldown"`
	Totalunknown int64 `json:"totalunknown"`
}

type UptimeReports []*UptimeReport

func (u *Status) uptimePercentage() float64 {
	if u.Totalup+u.Totaldown == 0 {
		return 1.0
	}
	return float64(u.Totalup) / (float64(u.Totaldown) + float64(u.Totalup))
}
func (u *Status) save(key string) {
	percentage := strconv.FormatFloat(u.uptimePercentage(), 'f', 8, 64)
	c.Set(key, percentage)
}

// Change in downtime percentage
func (u *Status) delta(key string) float64 {
	value, err := c.Get(key)
	if err != nil {
		return 0.0
	}
	old, err := strconv.ParseFloat(value.(string), 64)
	if err != nil {
		return 0.0
	}
	// If our uptime is up, we want to show a positive change instead of negative
	return (u.uptimePercentage() - old) / old
}
func (u *Status) Downtime() time.Duration {
	return time.Duration(u.Totaldown)
}

func (u *UptimeReport) save() {
	// key-format is id-(days_ago)
	id := strconv.Itoa(u.Id)
	u.DayAgo.save(id + "1")
	u.WeekAgo.save(id + "7")
	u.MonthAgo.save(id + "30")
}

func (u *UptimeReport) deltas() []float64 {
	id := strconv.Itoa(u.Id)
	return []float64{
		u.DayAgo.delta(id + "1"),
		u.WeekAgo.delta(id + "7"),
		u.MonthAgo.delta(id + "30"),
	}
}

func (ur UptimeReports) dailyUptime() float64 {
	var up int64
	var down int64
	for _, u := range ur {
		up += u.DayAgo.Totalup
		down += u.DayAgo.Totaldown
	}
	return float64(up) / float64(up+down)
}

func (ur UptimeReports) totalDailyDowntime() string {
	var sum time.Duration
	for _, u := range ur {
		sum += time.Duration(u.DayAgo.Totaldown)
	}
	sum = sum * time.Second
	return sum.String()
}

func (ur UptimeReports) weeklyUptime() float64 {
	var up int64
	var down int64
	for _, u := range ur {
		up += u.WeekAgo.Totalup
		down += u.WeekAgo.Totaldown
	}
	return float64(up) / float64(up+down)
}

func (ur UptimeReports) totalWeeklyDowntime() string {
	var sum time.Duration
	for _, u := range ur {
		sum += time.Duration(u.WeekAgo.Totaldown)
	}
	sum = sum * time.Second
	return sum.String()
}

func (ur UptimeReports) monthlyUptime() float64 {
	var up int64
	var down int64
	for _, u := range ur {
		up += u.MonthAgo.Totalup
		down += u.MonthAgo.Totaldown
	}
	return float64(up) / float64(up+down)
}
func (ur UptimeReports) totalMonthlyDowntime() string {
	var sum time.Duration
	for _, u := range ur {
		sum += time.Duration(u.MonthAgo.Totaldown)
	}
	sum = sum * time.Second
	return sum.String()
}

func (ur UptimeReports) save() {
	var wg sync.WaitGroup
	wg.Add(len(ur))
	for _, u := range ur {
		go func(u *UptimeReport) {
			defer wg.Done()
			u.save()
		}(u)
	}
	wg.Wait()
}

// sort in ascending order
func (ur UptimeReports) Len() int      { return len(ur) }
func (ur UptimeReports) Swap(i, j int) { ur[i], ur[j] = ur[j], ur[i] }
func (ur UptimeReports) Less(i, j int) bool {
	return ur[i].DayAgo.uptimePercentage() < ur[j].DayAgo.uptimePercentage()
}
