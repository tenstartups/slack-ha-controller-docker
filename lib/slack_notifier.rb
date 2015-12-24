require 'slack-notifier'

module Slackhook
  class SlackNotifier
    def initialize(webhook_url: nil, user_name: nil, icon_url: nil)
      @webhook_url = webhook_url
      @user_name = user_name
      @icon_url = icon_url
      @notify_colors = {
        debug: '#551a8b',
        info: '#999999',
        success: 'good',
        warn: 'warning',
        error: 'danger'
      }
    end

    %i( debug info success warn error).each do |severity|
      define_method severity do |message, **options|
        options ||= {}
        options.merge!(severity: severity)
        options = options.keys.reduce({}) { |a, e| a[e.to_sym] = options[e]; a }
        send(:notify, message, **options)
      end
    end

    def notify(message, severity: 'info', attachment: nil)
      return if @webhook_url.nil?
      username = "#{@user_name || ENV['HOSTNAME'].split('.').first} (#{severity})"
      notifier = Slack::Notifier.new(@webhook_url, username: username)
      params = {}
      params.merge! icon_url: @icon_url if @icon_url
      params.merge! attachments: [{ fallback: message, text: attachment, color: @notify_colors[severity.to_sym] }] if attachment
      notifier.ping(message, params)
    end
  end
end
