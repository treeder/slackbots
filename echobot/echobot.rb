require_relative 'bundle/bundler/setup'
require 'uri'
require 'slack-notifier'
require 'iron_worker'
require 'slack_webhooks'

sh = SlackWebhooks::Hook.new('echobot', IronWorker.payload, IronWorker.config['webhook_url'])

# Slice off the 'echo' text
text = sh.text.split(' ')[1..-1].join(' ')

sh.send(text)
