

TODO: link to blog post

All of the examples in this repository follow the same pattern for testing and uploading to IronWorker. That pattern
is as follows:

1) Create an Incoming Webhook URL in Slack, then create a config file, `config.json`, that looks like this:

```json
{
  "webhook_url": "https://hooks.slack.com/services/abc/123/xyz"
}
```

2) Install dependencies

```sh
docker run --rm -v "$(pwd)":/worker -w /worker iron/images:ruby-2.1 sh -c 'bundle install --standalone'
```

3) Test

First get copy the sample payload from here: https://github.com/iron-io/slackbots/blob/master/hellobot/slack.payload .

Then run it the bot with the sample payload to test it:

```sh
docker run --rm -v "$(pwd)":/worker -w /worker iron/images:ruby-2.1 sh -c 'ruby <BOTNAME>.rb -payload slack.payload -config config.json'
```

4) Upload to IronWorker

```sh
zip -r <BOTNAME>.zip .
iron worker upload --stack ruby-2.1 --config-file config.json <BOTNAME>.zip ruby <BOTNAME>.rb
```

Grab the URL the upload command prints to the console and go to it in your browser, it will look something like this:

https://hud.iron.io/tq/projects/4fd2729368/code/50fd7a3051df9225ba

On that page, you’ll see a Webhook URL, it will look something like this:

https://worker-aws-us-east-1.iron.io/2/projects/4fd2729368/tasks/webhook?code_name=hello&oauth=abc

Copy that URL, we'll use it in the next step. 

5) Create a Slash Command integration in Slack

In Slack, go to Integrations, find Slash Commands, click Add, type in /<BOTNAME> as the command then click Add again. 
On the next page, take the IronWorker’s webhook URL you got in the step above and paste it into the URL field then click Save Integration.

6) Try it out!

In slack, type `/<BOTNAME>` and you'll see the magic!

