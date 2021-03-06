require 'open3'
require 'singleton'

module Slackhook
  module Action
    class Error < StandardError; end

    class Base
      include Singleton
      include LoggingHelper

      attr_accessor :config

      def config
        @config ||= {}
      end

      private

      def slack_message
        Thread.current.thread_variable_get(:slack_message)
      end

      def slack_notifier
        Thread.current.thread_variable_get(:slack_notifier)
      end

      def run(command)
        Open3.popen2e(command) do |stdin, stdout_and_stderr, wait_thr|
          stdout_and_stderr.each_line do |line|
            next if line.try(:strip).blank?
            line.strip.split(/[^[:print:]]/i).each do |l|
              l = l[/^\s*(?<control>\[\d*[BAKm])?(?<line>.*)\s*$/i, :line]
              next if l.blank?
              info(l)
            end
          end
          unless wait_thr.value.success?
            error "Command `#{command}` failed!"
            fail Error, "Command `#{command}` failed!"
          end
        end
      rescue StandardError
        raise Error, "Command `#{command}` failed!"
      end
    end
  end
end
