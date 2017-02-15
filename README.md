# Serverless Slackbots for IronFunctions

All of the examples in this repository follow the same pattern building, testing and deploying. 

First be sure you've install the `fn` cli tool, [check here for instructions](https://github.com/iron-io/functions#quickstart). 

Then `cd` into the the bot's directory in this repo and do the following: 

### 1) Install dependencies

These bots are all written in Ruby so we need to install the gems. You don't even need Ruby installed though, just Docker. 

```sh
docker run --rm -v ${pwd}:/worker -w /worker iron/ruby:dev sh -c 'bundle install --standalone --clean'
```

### 2) Build and Test

Each bot directory has a slack.payload file that is an example file so you can run a quick test that will
post a message to slack. Run it with this command: 

```sh
fn build
cat slack.payload | fn run
```

### 3) Deploy

Assuming you already [have an app](https://github.com/iron-io/functions#create-an-application) on an IronFunctions installation. 

```sh
# Push function for distribution
fn push
# Create a route in the mybots app at the path /guppy to our brand new function!
fn routes create mybots /guppy
```

### 4) Create a Slash Command integration in Slack

In Slack, go to Integrations, find Slash Commands, click Add, type in /<BOTNAME> as the command then click Add again. 
On the next page, paste in your new bots URL, for example: http://your-functions-servers.com/r/mybots/guppy , and paste it into the URL
field then click Save Integration.

### 5) Try it out!

In slack, type `/<BOTNAME> [options]` and you'll see the magic!
