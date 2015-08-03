require_relative 'bundle/bundler/setup'
require 'iron_worker'
require 'slack_webhooks'
require 'iron_cache'
require 'fog'
require 'amazon-pricing'
require 'slack'

slack = Slack::Client.new(:token => IronWorker.config['slack_token'])
channel = IronWorker.config['channel']
channel_id = "x"

# apparently the only way to get the channel id is like this:
slack.channels_list['channels'].each do |c|
  # puts "name: #{c['name']}, id: #{c['id']}"
  if c['name'] == channel || c['name'] == channel[1..channel.length]
    channel_id = c['id']
    break
  end
end

# todo: since this one uses the api directly already, don't bother with incoming webhook
sh = SlackWebhooks::Hook.new('costbot', IronWorker.payload, IronWorker.config['webhook_url'])
sh.icon_url = "http://images.clipartpanda.com/save-money-icon-save-money-icon-iebaaazn.png"
sh.channel = channel

@ic = IronCache::Client.new
@cache = @ic.cache("costbot")

compute = Fog::Compute.new(
    :provider => :aws,
    :aws_secret_access_key => IronWorker.config['aws']['secret_key'],
    :aws_access_key_id => IronWorker.config['aws']['access_key']
)

reserved_hash = {}
reserved = compute.describe_reserved_instances
reserved.body['reservedInstancesSet'].each do |ris|
  next if ris['state'] != 'active'
  # p ris
  # todo: use offeringType, maybe use amount too?  amount is hourly cost, fixed price is up front cost
  az = ris['availabilityZone']
  itype = ris['instanceType']
  azhash = reserved_hash[az] || {}
  itypehash = azhash[itype] || {}
  itypehash['count'] = (itypehash['count']||0) + ris['instanceCount']
  azhash[itype] = itypehash
  reserved_hash[az] = azhash
end

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


def write_table(filename, table)
  File.open(filename, 'w') do |file|
    table.each do |row|
      row.each do |c|
        file.write(c)
        file.write(',')
      end
      file.write("\n")
    end
  end
end

def stringify_table(table, separator=",")
  s = ""
  table.each do |row|
    row.each do |c|
      s << c << separator
    end
    s << "\n"
  end
  s
end

# Sort project costs by cost desc
sorted_projects = projects.sort_by { |k,v| v['price_per_month'] }.reverse

total_cost = 0.0
projects_costs_table = [["Project", "Servers", "Monthly Cost"]]
sorted_projects.each_with_index do |a,i|
  k = a[0]
  v = a[1]
  total_cost += v['price_per_month']
  puts "#{k}, count: #{v['count']}, price_per_month: #{sprintf('$%.2f', v['price_per_month'])}"
  # p v['azs']
  projects_costs_table << ["#{k}", "#{v['count']}", "#{sprintf('$%.2f', v['price_per_month'])}"]
end

write_table('costs.csv', projects_costs_table)

# Now for RI coverage
total_servers = 0
total_covered = 0
extra_ris = 0
ri_table = [["Zone","Type","Count","RI's","NOT Covered"]]
File.open('ri-coverage.csv', 'w') do |file|
  byzone.each_pair do |zone,v|
    ris = reserved_hash[zone] || {}
    v.each_pair do |itype,itv|
      # Now compare v to ris
      rit = ris[itype] || {}
      icount = itv['count']
      ricount = rit['count'] || 0
      uncovered = icount - ricount
      ri_table << ["#{zone}","#{itype}","#{icount}","#{ricount}","#{uncovered}"]
      total_servers += icount
      if uncovered < 0
        extra_ris += -uncovered
        total_covered += icount
      else
        total_covered += ricount
      end
    end
  end
end
write_table('ri-coverage.csv', ri_table)


# todo: Store yesterdays data then compare to show differences
# expires_in = 86400
# users_vote_key = "#{votename}-user:#{sh.username}"
# item = @cache.get(users_vote_key)
# if item
# end
# @cache.put(users_vote_key, split[1], :expires_in => expires_in)

attachments = []

percent_covered = 1.0 * total_covered / total_servers * 100.0
p percent_covered
if percent_covered < 75.0
  text = "Coverage is Bad!"
  color = "warning"
else
  text = "Coverage is OK"
  color = "#00CC66"
end
fallback = text
attachment = {
    "fallback" => fallback,
    "text" => text,
    "color" => color,
    "mrkdwn_in" => ["text", "pretext"],
    "fields" => [
        {
            "title" => "Servers",
            "value" => "#{total_servers}",
            "short" => true
        },
        {
            "title" => "Covered",
            "value" => "#{total_covered}",
            "short" => true
        },
        {
            "title" => "Est. Monthly Cost",
            "value" => "#{sprintf('$%.2f', total_cost)}",
            "short" => true
        },
        {
            "title" => "Percent Covered",
            "value" => "#{sprintf('%.0f', percent_covered)}%",
            "short" => true
        },
        {
            "title" => "Unused Ri's",
            "value" => "#{extra_ris}",
            "short" => true
        },

    ]
}
attachments << attachment

channels = "#{channel_id}" # comma separated list
content = stringify_table(projects_costs_table, "\t")
p content
p slack.files_upload(content: content, title: "Costs by Project.md", channels: channels)
content = stringify_table(ri_table, "\t")
p content
p slack.files_upload(content: content, title: "RI Coverage.md", channels: channels)

# my_file = Faraday::UploadIO.new("x.html", 'text/html')
# p slack.files_upload(file: my_file, filetype: 'text/html')

sh.send("This is your daily server report.", attachments: attachments)
