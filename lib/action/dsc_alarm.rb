require 'rest-client'

module Slackhook
  module Action
    class DSCAlarm < Base
      def disarm(code:)
        slack_msg = Thread.current.thread_variable_get(:slack_message)
        info 'Disarming alarm'
        RestClient.post("#{dsc_alarm_uri}/disarm", code: code)
      end

      def arm_stay(**args)
        slack_msg = Thread.current.thread_variable_get(:slack_message)
        info 'Arming alarm in stay mode'
        RestClient.post("#{dsc_alarm_uri}/arm_stay", {})
      end

      def arm_away(**args)
        slack_msg = Thread.current.thread_variable_get(:slack_message)
        info 'Arming alarm in away mode'
        RestClient.post("#{dsc_alarm_uri}/arm_away", {})
      end

      private

      def dsc_alarm_uri
        @dsc_alarm_uri ||= ENV['DSC_CONNECT_URI'] if ENV['DSC_CONNECT_URI'] && ENV['DSC_CONNECT_URI'].length > 0
        @dsc_alarm_uri ||= config[:uri]
        @dsc_alarm_uri ||= 'http://dsc-connect:8080'
      end
    end
  end
end
