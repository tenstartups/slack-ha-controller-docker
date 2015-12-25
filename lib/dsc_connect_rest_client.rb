require 'rest-client'
require 'singleton'

module Slackhook
  class DSCConnectRestClient
    include Singleton
    include LoggingHelper

    def disarm(code:)
      slack_msg = Thread.current.thread_variable_get(:slack_message)
      info 'Disarming alarm'
      RestClient.post("#{dsc_connect_uri}/disarm", code: code)
    end

    def arm_stay(**args)
      slack_msg = Thread.current.thread_variable_get(:slack_message)
      info 'Arming alarm in stay mode'
      RestClient.post("#{dsc_connect_uri}/arm_stay", {})
    end

    def arm_away(**args)
      slack_msg = Thread.current.thread_variable_get(:slack_message)
      info 'Arming alarm in away mode'
      RestClient.post("#{dsc_connect_uri}/arm_away", {})
    end

    private

    def dsc_connect_uri
      @dsc_connect_uri ||= ENV['DSC_CONNECT_URI'] if ENV['DSC_CONNECT_URI'] && ENV['DSC_CONNECT_URI'].length > 0
      @dsc_connect_uri ||= Configuration.instance.action_handlers.try(:dsc_connect).try(:uri)
      @dsc_connect_uri ||= 'http://dsc-connect:8080'
    end
  end
end
