All of the examples in this repository follow the same pattern for testing and uploading to IronWorker. Just `cd`
into the bots directory and do the following: 

### 1) Create an Incoming Webhook URL in Slack, then create a config file, `config.json`, that looks like this:

```json
{
  "webhook_url": "https://hooks.slack.com/services/abc/123/xyz"
}
```

You can reuse this same incoming URL for all your bots so you don't have to keep making new ones. 

### 2) Install dependencies

```sh
docker run --rm -v "$(pwd)":/worker -w /worker iron/images:ruby-2.1 sh -c 'bundle install --standalone'
```

### 3) Test

Each bot directory has a slack.payload file that is an example file so you can run a quick test that will
post a message to slack. Run it with this command: 

```sh
docker run --rm -v "$(pwd)":/worker -w /worker iron/images:ruby-2.1 sh -c 'ruby <BOTNAME>.rb -payload slack.payload -config config.json'
```

### 4) Upload to IronWorker

```sh
zip -r <BOTNAME>.zip .
iron worker upload --stack ruby-2.1 --config-file config.json <BOTNAME>.zip ruby <BOTNAME>.rb
```

Grab the URL that will be printed after you run the previous command and surf to it in your browser, it will look 
something like this:

```
https://hud.iron.io/tq/projects/4fd2729368/code/50fd7a3051df9225ba
```

On that page, you’ll see a Webhook URL, it will look something like this:

```
https://worker-aws-us-east-1.iron.io/2/projects/4fd2729368/tasks/webhook?code_name=hello&oauth=abc
```

Copy that URL, we'll use it in the next step. 

### 5) Create a Slash Command integration in Slack

In Slack, go to Integrations, find Slash Commands, click Add, type in /<BOTNAME> as the command then click Add again. 
On the next page, take the IronWorker’s webhook URL you got in the step above and paste it into the URL
field then click Save Integration.

### 6) Try it out!

In slack, type `/<BOTNAME> [options]` and you'll see the magic!

