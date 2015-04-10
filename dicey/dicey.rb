require_relative 'bundle/bundler/setup'
require 'iron_worker'
require 'slack_webhooks'

sh = SlackWebhooks::Hook.new('dicey', IronWorker.payload, IronWorker.config['webhook_url'])
sh.icon_url = "http://www.psdgraphics.com/file/red-dice-icon.jpg"
max = 6
if sh.text != nil && sh.text != ""
  max = sh.text.to_i
  if max <= 0
    max = 6
  end
end
text = "#{sh.username} rolled a *#{1 + rand(max)}*"
sh.send(text)
