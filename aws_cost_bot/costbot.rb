require_relative 'bundle/bundler/setup'
require 'iron_worker'
require 'slack_webhooks'
require 'iron_cache'
require 'fog'
require 'amazon-pricing'

sh = SlackWebhooks::Hook.new('votey', IronWorker.payload, IronWorker.config['webhook_url'])
sh.icon_url = "http://s2.hubimg.com/u/7842695_f260.jpg"
sh.set_usage "Usage: /vote <vote_name> <yes/no>"
exit if sh.help?

@ic = IronCache::Client.new
@cache = @ic.cache("votey")

compute = Fog::Compute.new(
    :provider => :aws,
    :aws_secret_access_key => IronWorker.config['aws']['secret_key'],
    :aws_access_key_id => IronWorker.config['aws']['access_key']
)

reserved_hash = {}
reserved = compute.describe_reserved_instances
reserved.body['reservedInstancesSet'].each do |ris|
  next if ris['state'] != 'active'
  p ris
  # todo: use offeringType, maybe use amount too?  amount is hourly cost, fixed price is up front cost
  az = ris['availabilityZone']
  itype = ris['instanceType']
  azhash = reserved_hash[az] || {}
  itypehash = azhash[itype] || {}
  itypehash['count'] = (itypehash['count']||0) + ris['instanceCount']
  azhash[itype] = itypehash
  reserved_hash[az] = azhash
end

p reserved_hash

# Retrieve pricing
price_list = AwsPricing::Ec2PriceList.new

byzone = {}
projects = {}

puts "Region,Availability Zone,Instance Id,Instance IP,Instance Type,On-Demand Price Per Month"
compute.servers.each do |server|
  # p server
  region = server.availability_zone[0...server.availability_zone.length-1]
  # p region
  # r2 = price_list.get_region(region)
  # p r2.ec2_instance_types[0].name
  # exit
  az = server.availability_zone
  itype = server.flavor_id

  instance_type = price_list.get_instance_type(region, server.flavor_id)
  price_per_hour = instance_type.price_per_hour(:linux, :ondemand)
  price_per_month = price_per_hour*24*30.4
  project_name = server.tags['Name']

  project_hash = projects[project_name] || {}
  project_hash['price_per_month'] = (project_hash['price_per_month'] || 0.0) + price_per_month
  project_hash['count'] = (project_hash['count'] || 0) + 1

  azs = project_hash['azs'] || {}
  azhash = azs[az] || {}
  itypehash = azhash[itype] || {}
  itypehash['count'] = (itypehash['count']||0) + 1
  azhash[itype] = itypehash
  azs[az] = azhash
  project_hash['azs'] = azs

  projects[project_name] = project_hash

  # also aggregate by zone/type
  azhash = byzone[az] || {}
  itypehash = azhash[itype] || {}
  itypehash['count'] = (itypehash['count']||0) + 1
  azhash[itype] = itypehash
  byzone[az] = azhash

  # puts "#{project_name}, #{region},#{az},#{server.id},#{server.public_ip_address},#{itype},$#{price_per_hour},$#{price_per_month}"
end

projects.each_pair do |k,v|
  puts "#{k}, count: #{v['count']}, price_per_month: #{sprintf('$%.2f', v['price_per_month'])}"
  p v['azs']
end

File.open('costs.csv', 'w') do |file|
  projects.each_pair do |k,v|
    file.write("#{k},#{v['count']},#{v['price_per_month']}\n")
  end
end

p byzone

# Now for RI coverage

File.open('ri-coverage.csv', 'w') do |file|
  byzone.each_pair do |zone,v|
    ris = reserved_hash[zone] || {}
    v.each_pair do |itype,itv|
      # Now compare v to ris
      rit = ris[itype] || {}
      file.write("#{zone},#{itype},#{itv['count']},#{rit['count']}\n")
    end
  end
end



exit





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
yeses = 0
nos = 0
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
if !yr.nil?
  yeses = yr.value
end
if !nr.nil?
  nos = nr.value
end
puts "yeses: #{yeses}"
puts "nos: #{nos}"

text = ""
color = "warning"
if yeses > nos
  color = "good"
elsif yeses < nos
  color = "danger"
end

attachment = {
    "fallback" => text,
    "text" => "Voting results for `/vote #{votename}`",
    "color" => color,
    "mrkdwn_in" => ["text", "pretext"],
    "fields" => [
        {
            "title" => "Yes",
            "value" => "#{yeses}",
            "short" => true
        },
        {
            "title" => "No",
            "value" => "#{nos}",
            "short" => true
        },
    ]
}

sh.send(text, attachment: attachment)
