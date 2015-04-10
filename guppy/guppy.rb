require_relative 'bundle/bundler/setup'
require 'open-uri'
require 'slack-notifier'
require 'iron_worker'
require 'slack_webhooks'

# Comment out the next line and uncomment the one after to load the commands.json from your local file
# rather than the URL
responses = JSON.load(open('https://raw.githubusercontent.com/treeder/slackbots/master/guppy/commands.json'))
# Use this one to load from file: responses = JSON.load(File.open('commands.json'))

sh = SlackWebhooks::Hook.new('guppy', IronWorker.payload, IronWorker.config['webhook_url'])

attachment = {
    "fallback" => "wat?!", # "(╯°□°）╯︵ ┻━┻)",
    "image_url" => "http://i.imgur.com/7kZ562z.jpg"
}

help = "Available options are:\n"
responses.each_key { |k| help << "* #{k}\n" }
# puts help

r = responses[sh.text]
if r
  attachment['image_url'] = r['image_url']
else
  # send help directly to user
  sh.channel = sh.username
  if sh.text == "help"
    attachment['text'] = "#{help}"
  else
    attachment['text'] = "You gave me #{sh.text} -- Je ne comprend pas.\n#{help}"
  end
end

s = "#{sh.command} #{sh.text}"
sh.send s, attachment: attachment
