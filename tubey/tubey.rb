require_relative 'bundle/bundler/setup'
require 'youtube_it'
require 'iron_worker'
require 'slack_webhooks'

sh = SlackWebhooks::Hook.new('tubey', IronWorker.payload, IronWorker.config['webhook_url'])
sh.icon_url = 'https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2015-03-10/3999143873_e2fb4ca39b4876bb0bf2_48.jpg'

client = YouTubeIt::Client.new
vids = client.videos_by(:query => sh.text, :safe_search => "strict")
# p vids
puts "count: #{vids.total_result_count}"
vids.videos.each do |v|
  puts "name: #{v.title}"
end

# Video object attributes: https://github.com/kylejginavan/youtube_it/blob/master/lib/youtube_it/model/video.rb
v = vids.videos.sample
puts "sample: #{v.title} #{v.player_url}"

sh.send("#{sh.command} #{sh.text}\n#{v.player_url}")
