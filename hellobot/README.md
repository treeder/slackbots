
TODO: link to blog post

1) Get an Incoming Webhook URL from Slack Integrations and create config file

Create an Incoming Webhook URL in Slack, then create a config file that looks like this:

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

```sh
docker run --rm -v "$(pwd)":/worker -w /worker iron/images:ruby-2.1 sh -c 'ruby hellobot.rb -payload hello.payload -config config.json'
```

4) Upload to IronWorker

```sh
zip -r hellobot.zip .
iron worker upload --stack ruby-2.1 --config-file config.json hellobot.zip ruby hellobot.rb
```

5) Add Slash Command to Slack to run this bot/worker

Go to the HUD URL that will be printed after the upload command above, you'll see a Webhook URL. 
Then go to Slack and add a Slash Command for `/hello` and paste the workers webhook URL as the URL the 
slash command will hit. 

6) Try it out!

In slack, type `/hello` and you'll see the magic!


