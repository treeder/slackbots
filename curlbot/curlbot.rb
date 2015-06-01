require_relative 'bundle/bundler/setup'
require 'iron_worker'
require 'slack_webhooks'

sh = SlackWebhooks::Hook.new('curlbot', IronWorker.payload, IronWorker.config['webhook_url'])

s = `curl --silent #{sh.text}`
puts s

attachment = {
    "fallback" => s,
    "title" => "Response:",
    # "title_link" => "somelink",
    # "text" => "```pre\n#{s}\n```",
    "text" => s,
}

sh.send("/curl #{sh.text}", attachment: attachment)
