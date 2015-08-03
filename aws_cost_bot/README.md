Given a set of AWS credential, this bot will go check all your servers and the costs associated with them, aggregated by Name. 

## Additional steps required to run this Bot

### 1) Make an iron.json file 

This bot uses [IronCache](http://www.iron.io/cache) to store results temporarily. 
Create an iron.json file in this directory with your Iron.io project_id and token. 

### 2) Add your AWS credentials to config.json 

Copy `config-example.json` to `config.json` and fill it in. 

### 3) Test it

```
docker run --rm -v "$(pwd)":/worker -w /worker iron/images:ruby-2.1 sh -c 'ruby costbot.rb -payload slack.payload -config config.json'
```

### 4) Upload it

```
zip -r costbot.zip .
iron worker upload --name costbot --zip costbot.zip iron/images:ruby-2.1 ruby costbot.rb
```

### 5) Schedule it

This bot is intended to be scheduled, rather than turned into a slash command so instead of making a slash command, 
schedule it. After you upload, you'll see a link on your console to HUD where you can schedule it in the 
UI or you can use the command below:

```
iron worker schedule --start-at 2015-06-24T08:00:00Z --run-every 86400 --payload-file slack.payload costbot
```
