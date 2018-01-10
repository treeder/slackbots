require 'open-uri'
require 'slack_webhooks'
require 'json'

# Comment out the next line and uncomment the one after to load the commands.json from your local file
# rather than the URL
responses = JSON.load(open('https://raw.githubusercontent.com/treeder/slackbots/master/guppy/commands.json'))
# Use this one to load from file: responses = JSON.load(File.open('commands.json'))

payload = STDIN.read
STDERR.puts payload
if payload == ""
  # then probably just testing
  puts "Need a payload from Slack... :("
  return
end

sh = SlackWebhooks::Hook.new('guppy', payload, nil)

attachment = {
    "fallback" => "wat?!", # "(╯°□°）╯︵ ┻━┻)",
    "image_url" => "http://i.imgur.com/7kZ562z.jpg"
}

r = responses[sh.text]
if r
  attachment['image_url'] = r['image_url']
else
  # help
  help = "Available options are:\n"
  responses.each_key { |k| help << "* #{k}\n" }
  response = {
    "response_type" => "ephemeral",
    "text" => help,
    "attachments" => [attachment]
  }
  s = response.to_json
  STDERR.puts "responding with #{s}"
  puts s
  exit
end

s = "#{sh.command} #{sh.text}"
response = {
  "response_type" => "in_channel",
  "text" => s,
  "attachments" => [attachment]
}
puts response.to_json
