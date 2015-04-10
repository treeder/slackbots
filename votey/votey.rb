require_relative 'bundle/bundler/setup'
require 'iron_worker'
require 'slack_webhooks'
require 'iron_cache'

sh = SlackWebhooks::Hook.new('votey', IronWorker.payload, IronWorker.config['webhook_url'])
sh.icon_url = "http://s2.hubimg.com/u/7842695_f260.jpg"
sh.set_usage "Usage: /vote <vote_name> <yes/no>"
exit if sh.help?

@ic = IronCache::Client.new
@cache = @ic.cache("votey")

expires_in = 86400
split = sh.text.split(' ')
if split.length < 2
  sh.send_usage("Invalid parameters.")
  exit
end
votename = split[0]
if split[1][0] != 'y' && split[1][0] != 'n'
  sh.send_usage("Must be yes or no")
  exit
end
# Ok, input looks ok, let's continue

yes = split[1][0] == 'y'
# Store what the user posted so we don't count it twice
users_vote_key = "#{votename}-user:#{sh.username}"
item = @cache.get(users_vote_key)
changed = false
already_voted = false
if item
  already_voted = true
  # then user already voted, if it changed, we can change the counts
  if item.value[0] == split[1][0]
    # Same so do nothing
  else
    changed = true
    # change votes
  end
end
yinc = 0
ninc = 0
@cache.put(users_vote_key, split[1], :expires_in => expires_in)
if already_voted
  if changed
    # need to update both
    if yes
      yinc = 1
      ninc = -1
    else
      yinc = -1
      ninc = 1
    end
  end
else
  if yes
    yinc = 1
  else
    ninc = 1
  end
end

yeskey = "#{votename}-yes"
nokey = "#{votename}-no"
yr = nil
nr = nil
if yinc != 0
  yr = @cache.increment(yeskey, yinc, :expires_in => expires_in)
end
if ninc != 0
  nr = @cache.increment(nokey, ninc, :expires_in => expires_in)
end
if yr.nil?
  yr = @cache.get(yeskey)
end
if nr.nil?
  nr = @cache.get(nokey)
end
puts "yeses: #{yr.value}"
puts "nos: #{nr.value}"

text = ""
color = "warning"
if yr.value > nr.value
  color = "good"
elsif yr.value < nr.value
  color = "danger"
end

attachment = {
    "fallback" => text,
    "text" => "Voting results",
    "color" => color,
    "fields" => [
        {
            "title" => "Yes",
            "value" => "#{yr.value}",
            "short" => true
        },
        {
            "title" => "No",
            "value" => "#{nr.value}",
            "short" => true
        },
    ]
}

sh.send(text, attachment: attachment)
