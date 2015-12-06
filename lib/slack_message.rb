#!/usr/bin/env ruby
require 'cgi'
require 'ostruct'
require 'shellwords'
require 'slack-notifier'

class SlackMessage < OpenStruct
  include LoggingHelper

  def initialize(params)
    super(params)
    self.command = command[%r{^/?(.*)$}, 1]
    self.text_words = text.split(' ').map(&:strip)
    @response_colors = {
      debug: '#551a8b',
      info: '#999999',
      success: 'good',
      warn: 'warning',
      error: 'danger'
    }
  end

  def display
    ["/#{command}"].concat(text_words).join(' ')
  end

  def attributes
    to_h.select { |k, v| %i[ team_domain channel_name user_name command text ].include?(k) }
  end

  %i[ debug info success warn error].each do |severity|
    define_method severity do |message, **options|
      options ||= {}
      options.merge!(severity: severity)
      options = options.keys.reduce({}) { |a, e| a[e.to_sym] = options[e]; a }
      send(:respond, message, **options)
    end
  end

  def respond(message, severity: 'info', attributes: {})
    send :log, severity, message
    notifier = Slack::Notifier.new(response_url)
    params = {
      attachments: [
        {
          fallback: message,
          title: "#{severity.to_s.titleize} response",
          text: message,
          color: @response_colors[severity.to_sym],
          fields: attributes.map do |n, v|
            { title: n, value: v, short: v.nil? || v.to_s.length < 15 }
          end
        }
      ]
    }
    notifier.ping(message, params)
  end
end
