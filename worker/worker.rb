require_relative 'bundle/bundler/setup'
require 'iron_worker'
require 'slack_webhooks'

project_id = nil
token = nil
worker_name = nil
payload_for_worker = nil
send_usage = false

sh = SlackWebhooks::Hook.new('worker', IronWorker.payload, IronWorker.config['webhook_url'])
ts = sh.text.split(' ')
if ts.length < 3
  send_usage = true
else
  project_id = ts[0]
  token = ts[1]
  worker_name = ts[2]
  payload = ts[3..-1].join(' ')
end

puts "project_id=#{project_id} token=#{token} worker_name=#{worker_name} payload=#{payload_for_worker}"

if send_usage
  puts "invalid params passed in, sending usage"
  sh.channel = sh.username
  sh.send("Usage: /worker <project_id> <token> <worker_name> <payload>")
  exit
end

puts "all good queuing task"
wc = IronWorker::Client.new(project_id: project_id, token: token)
task = wc.tasks.create(worker_name, payload)
puts "task_id=#{task.id}"
wc.tasks.wait_for(task.id) do |t|
  puts t.msg
end
log = wc.tasks.log(task.id)
puts log

attachment = {
    "fallback" => "wat?!",
    "title" => "Worker '#{worker_name}' executed",
    "title_link" => "https://hud.iron.io/tq/projects/#{project_id}/tasks/#{task.id}",
    "text" => log,
    # "image_url" => "http://i.imgur.com/7kZ562z.jpg"
    # "color": "#764FA5"
}

sh.send("/worker #{project_id} <TOKEN> #{worker_name} #{payload}", attachment: attachment)
