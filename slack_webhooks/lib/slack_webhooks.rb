require 'uri'
require 'slack-notifier'
require_relative 'slack_webhooks/version'

module SlackWebhooks
  class Hook

    attr_accessor :command, :trigger_word, :channel, :username, :text, :webhook_url, :botname
    alias_method :user_name, :username

    # botname is the name to post to the channel with.
    # body is the outgoing webhook POST body that Slack sends.
    # webhook_url is the incoming webhook to post back to slack.
    def initialize(botname, body, webhook_url)
      self.botname = botname
      self.webhook_url = webhook_url
      parsed = URI.decode_www_form(body)
      parsed.each do |p|
        # puts "#{p[0]}=#{p[1]}"
        if p[0] == "command"
          self.command = p[1]
          puts "command=#{self.command}"
        end
        if p[0] == "trigger_word"
          # This is for trigger words, not slash commands
          self.trigger_word = p[1]
        end
        if p[0] == "channel_name"
          self.channel = p[1]
        end
        if p[0] == "user_name"
          self.username = "@#{p[1]}"
          # puts "username #{username}"
        end
        if p[0] == "text"
          self.text = p[1].strip
          # puts "text=#{text}"
        end
      end
      if self.channel == "directmessage"
        self.channel = self.username
      else
        self.channel = "\##{self.channel}" unless self.channel[0] == '#'
      end

    end

    def send(s, attachment=nil)
      # Now send it to back to the channel on slack
      s = "#{command} #{text}" if s.nil?
      puts "Posting #{s} to #{channel}. .."
      notifier = Slack::Notifier.new webhook_url
      notifier.channel = channel
      notifier.username = botname

      resp = nil
      if attachment
        resp = notifier.ping s, attachments: [attachment]
      else
        resp = notifier.ping s
      end

      p resp
      p resp.message
    end
  end
end
