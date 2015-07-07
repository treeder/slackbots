# Uptime bot

Uptime bot uses pingdom checks to determing the total uptime for all services. Uptime is an aggregate, not an average.
Pingdom requires your username, password, and api token in order to use their api. Due to the amount of redundant checks we have, this version requires you to supply the ids of the checks you want to use. In our specific case, we have three different sets: mq checks, worker checks, and other services.

## How to use

#### Put your pingdom username, password, and api token in the config file.
```json
{
  "username": "USERNAME",
  "password": "PASSWORD",
  "api_token": "API_TOKEN"
```

#### Put the slack webhook url you want to use
```json
  "webhook_url": "WEBHOOKURL"
```

#### Put in the ids of the checks you want to use.
```json
  "mq": [
    123,
    123
  ],
  "worker": [
     123,
     123
  ],
  "other": [
     123,
     123
  ]
}
```
#### Run `go build` to build the binary.
`./uptime` to run the program.

## Uploading to iron worker
#### Build the binary for amd64
```
GOOS=linux GOARCH=amd64 go build
```

#### Zip the folder
```
zip -r uptime.zip .
```

#### Upload to ironworker
```
iron worker upload --zip uptime.zip --name uptime iron/images:go-1.4 ./uptime
```
