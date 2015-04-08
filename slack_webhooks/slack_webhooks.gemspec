require_relative 'lib/slack_webhooks/version'

Gem::Specification.new do |s|
  s.name = 'slack_webhooks'
  s.version = SlackWebhooks::VERSION
  s.licenses = ['MIT']
  s.summary = "Helper for slack webhooks"
  s.description = "Helper for slack webhooks!"
  s.authors = ["Travis Reeder"]
  s.email = 'treeder@gmail.com'
  s.homepage = 'https://rubygems.org/gems/slack_webhooks'

  s.files = `git ls-files`.split($\)
#  s.executables = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
#  s.test_files = gem.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9")
  s.add_runtime_dependency "slack-notifier", ">= 0.5.1"
end
