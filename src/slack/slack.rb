require 'http'
require 'json'
require 'websocket-client-simple'

require_relative '../settings'

class Slack
  attr :res, :msg_lsnrs, :on_close

  def initialize
    res = HTTP.post "https://slack.com/api/rtm.start", params: {
      token: Settings[:Slack][:Token],
    }
    @res = JSON.parse res.body, symbolize_names: true

    @msg_lsnrs = []

    @soc = WebSocket::Client::Simple.connect @res[:url]

    sl = self

    @soc.on :message do |d|
      data = JSON.parse d.data, symbolize_names: true

      pp data
      puts ?- * 50

      next if data[:user] == sl.res[:self][:id]

      case data[:type]
      when 'message'
        sl.msg_lsnrs.each{|r, f| f.call $~, data if r =~ data[:text] }
      when 'hello'
        sl.say 'Hello, world!'
      end
    rescue => e
      $stderr.puts e.inspect
      exit
    end

    @soc.on :close do |e|
      if sl.on_close then sl.on_close.call else exit end
    rescue => e
      $stderr.puts e.inspect
      exit
    end

  rescue => e
    $stderr.puts e.inspect
    exit
  end

  def listen_message re, &b
    @msg_lsnrs << [re, b]
  end

  def say text, channel = Settings[:Slack][:DefaultChannel]
    @soc.send ({
      type: 'message',
      text: text,
      channel: channel,
    }).to_json
  rescue => e
    $stderr.puts e.inspect
    exit
  end
end
