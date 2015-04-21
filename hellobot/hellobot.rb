require_relative 'bundle/bundler/setup'
require 'iron_worker'
require 'slack_webhooks'

sh = SlackWebhooks::Hook.new('hellobot', IronWorker.payload, IronWorker.config['webhook_url'])
text = "Hello #{sh.user_name}!"
sh.send(text)
