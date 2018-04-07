require_relative 'slack/slack'

Thread.abort_on_exception = true

slack = Slack.new

slack.listen_message /\Ah\z/ do |_, data|
  slack.say 'ぴょんぴょん', data[:channel]
end

loop{}
