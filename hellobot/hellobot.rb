require_relative 'bundle/bundler/setup'
require 'uri'
require 'slack-notifier'
require 'iron_worker'

# Incoming webhook URL from Slack
webhook_url = IronWorker.config['webhook_url']

# This is the payload Slack posts to the worker/bot when the command is typed by a user
payload = IronWorker.payload
puts "payload: #{p.inspect}"

# We need to find the channel the command was typed into so we can send our message back to the right one
channel = "#random"
user_name = "World"
parsed = URI.decode_www_form(payload)
parsed.each do |p|
  puts p[0]
  if p[0] == "channel_name"
    channel = p[1]
  end
  if p[0] == "user_name"
    user_name = "@#{p[1]}"
    puts "username #{user_name}"
  end
end
channel = "\##{channel}" unless channel[0] == '#'

# This is what we'll post back
text = "Hello #{user_name} !"

# Now send it to back to the channel on slack
puts "Posting #{text} to #{channel}. .."
notifier = Slack::Notifier.new webhook_url
notifier.channel  = channel
notifier.username = 'hellobot'
resp = notifier.ping text
p resp
p resp.message
puts "done "
