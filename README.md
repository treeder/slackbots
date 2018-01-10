# Slackbots for Fn Project

All of the examples in this repository follow the same pattern for testing and uploading to [Fn](https://fnproject.io). Assuming
you have an Fn server running and the CLI installed, just `cd`
into the bots directory and do the following:

## Deploy

```sh
fn deploy --app slackbots BOTNAME
```

## Create a Slash command in Slack

If you don't have a Slack app already, [start here](https://api.slack.com/apps).

In your app, click `Slash Commands` and create one that points to your deployed bot/function.

## Install the app into your team

You'll see `Install App` on the left side of your app in the Slack console. Click that and follow the directions.

### 6) Try it out!

Now in slack, type `/<BOTNAME> [options]` and you'll see the magic!
