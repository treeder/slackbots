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
#### Build the bot using docker
```
docker run --rm -v "$GOPATH":/gopath -e "GOPATH=/gopath" -v "$(pwd)":/worker -w /worker iron/images:go-1.4 sh -c 'go build -o uptime'
```

## Uploading to iron worker
#### Zip the folder
```
zip -r uptime.zip .
```

#### Upload to ironworker
```
iron worker upload --zip uptime.zip --name uptime iron/images:go-1.4 ./uptime
```

#### Run the worker
```
iron worker queue uptime
```
