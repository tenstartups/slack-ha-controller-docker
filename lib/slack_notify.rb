#!/usr/bin/env ruby
require 'slack-notifier'

class SlackNotify
  def initialize()
    @webhook_url = ENV['SLACK_WEBHOOK_URL']
    @notify_colors = {
      debug: '#551a8b',
      info: '#999999',
      success: 'good',
      warn: 'warning',
      error: 'danger'
    }
  end

  %i[ debug info success warn error].each do |severity|
    define_method severity do |message, **options|
      options ||= {}
      options.merge!(severity: severity)
      options = options.keys.reduce({}) { |a, e| a[e.to_sym] = options[e]; a }
      send(:notify, message, **options)
    end
  end

  def notify(message, severity: 'info', attachment: nil)
    puts message
    username = "#{ENV['SLACK_USER_NAME'] || ENV['HOSTNAME'].split('.').first} (#{severity})"
    notifier = Slack::Notifier.new(@webhook_url, username: username)
    params = { icon_url: ENV['SLACK_ICON_URL'] } if ENV['SLACK_ICON_URL']
    if attachment
      params.merge! attachments: [{fallback: message, text: attachment, color: @notify_colors[severity.to_sym]}]
    end
    notifier.ping(message, params)
  end
end
