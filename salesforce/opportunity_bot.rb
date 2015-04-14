require_relative 'bundle/bundler/setup'
require 'open-uri'
require 'iron_worker'
require 'slack_webhooks'
require 'google/api_client'
require 'restforce'
require_relative 'google_datastore'

# Config models
class SlackC
  attr_accessor :channel, :webhook_url
end
class SalesforceC
  attr_accessor :username,
                :password,
                :security_token,
                :client_id,
                :client_secret

  def set(h)
    h.each { |k, v| send("#{k}=", v) }
  end

  def to_hash
    # makes hash and symbolizes keys
    hash = {}
    instance_variables.each { |var| hash[var.to_s.delete("@").to_sym] = instance_variable_get(var) }
    hash
  end
end

class MyConfig
  attr_accessor :slack, :google, :salesforce

  def initialize
    @slack = SlackC.new
    @salesforce = SalesforceC.new
  end
end

config = MyConfig.new
config.salesforce.set(IronWorker.config['salesforce'])

config.slack.webhook_url = IronWorker.config['webhook_url']
config.slack.channel = IronWorker.config['channel']

config.google.project_id = "myproject"
config.google.service_account_id = "abc@developer.gserviceaccount.com"

gd = GoogleDatastore.new(config.google)

def get_opp_updates(config, gd)

  client = Restforce.new(config.salesforce.to_hash)

  last_check = gd.get_last_check
  # for testing:
  # last_check = Date.today.prev_day.to_datetime # "2015-01-01T00:00:01z"

  # Opportunity: https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_opportunity.htm
  query = "Select op.Id, op.Name, op.Amount, op.StageName, op.Probability, op.LastModifiedDate, op.CloseDate, op.AccountId, op.OwnerId from Opportunity op " +
      "where op.LastModifiedDate > #{last_check.to_datetime.rfc3339}"
  puts "query=#{query}"
  ops = client.query(query)
  posted = 0
  ops.each_with_index do |op, i|
    break if posted >= 3
    puts "op"
    p op
    puts "Op: id=#{op.Id} opname=#{op.Name} amount=#{op.Amount} probability=#{op.Probability}"
    p client.url(op)

    # Get account for the opp too
    query = "Select Id, Name, LastModifiedDate from Account where Id = '#{op.AccountId}'"
    puts "account query=#{query}"
    accounts = client.query(query)
    p accounts
    account = accounts.first

    # And owner
    query = "Select Id, Name, LastModifiedDate from User where Id = '#{op.OwnerId}'"
    puts "owner query=#{query}"
    owners = client.query(query)
    p owners
    owner = owners.first

    # OpportunityHistory: https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_opportunityhistory.htm
    history = client.query("select ID, StageName, Probability, Amount, ExpectedRevenue, CloseDate from OpportunityHistory where OpportunityId = '#{op.Id}' and CreatedDate > #{last_check.to_datetime.rfc3339}")
    history.each_with_index do |h, j|
      break if j >= 1 # only do one max
      puts "history"
      p h
      puts "History: id=#{h.Id} amount=#{h.Amount} stage=#{h.StageName} probability=#{h.Probability} closedate=#{h.CloseDate}"
      post_to_slack(config, client, op, account, owner, h)
      posted += 1
    end
  end

  gd.insert_new_check_date()
  puts "Posted #{posted} updates to slack. "

end

def post_to_slack(config, sclient, op, account, owner, h)
  if h.Amount.nil?
    puts "h.Amount is nil"
    return
  end

  # todo: ADD OWNER -author_name ?
  s = "Opportunity for <#{sclient.url(account)}|#{account.Name}> updated."
  attachment = {
      "fallback" => s,
      "pretext" => s,
      "title" => "#{op.Name}",
      "title_link" => sclient.url(op),
      # "text" => "Stage: #{h.StageName}",
      # "image_url" => "http://caldwelljournal.com/wp-content/uploads/2015/01/Boom.jpg",
      # "color": "#764FA5"
      "fields" => [
          {
              "title" => "Stage",
              "value" => "#{h.StageName}",
              "short" => true
          },
          {
              "title" => "Amount",
              "value" => "$#{'%.2f' % h.Amount}",
              "short" => true
          },
          {
              "title" => "Close Date",
              "value" => "#{op.CloseDate}",
              "short" => true
          },
          # {
          #     "title" => "Probability",
          #     "value" => "#{'%.0f' % h.Probability}%",
          #     "short" => true
          # },
          # {
          #     "title" => "Expected Revenue",
          #     "value" => "$#{'%.2f' % h.ExpectedRevenue}",
          #     "short" => true
          # },
          {
              "title" => "Owner",
              "value" => "#{owner.Name}",
              "short" => true
          },
      ]
  }
  # if op.StageName.include? "11"
  #   # there's also 'warning'
  #   attachment["color"] = 'danger'
  # elsif op.StageName.include?("06") || op.StageName.include?("08") || op.StageName.include?("10")
  #   attachment["color"] = 'good'
  # end

  if op.Probability >= 70
    # there's also 'warning'
    attachment["color"] = 'good'
  elsif op.Probability <= 20
    attachment["color"] = 'danger'
  elsif op.Probability <= 40
    attachment["color"] = 'warning'
  end
  if op.Probability == 100
    attachment["image_url"] = "http://caldwelljournal.com/wp-content/uploads/2015/01/Boom.jpg"
  end

  puts "posting #{attachment.inspect} to slack..."

  # uncomment line below for testing
  # sh.channel = sh.username

  # puts "Posting #{text} to #{channel}..."
  notifier = Slack::Notifier.new config.slack.webhook_url
  notifier.channel = "#{config.slack.channel}" if config.slack.channel
  notifier.username = 'salesbot'
  resp = notifier.ping "", attachments: [attachment]
  p resp
  p resp.message
  puts "done"
end

get_opp_updates(config, gd)

