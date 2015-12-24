module Slackhook
  class CommandBase
    include Singleton
    include LoggingHelper

    private

    def slack_message
      Thread.current.thread_variable_get(:slack_message)
    end

    def slack_notifier
      Thread.current.thread_variable_get(:slack_notifier)
    end

    def run(command)
      TaskHandler.instance.run(command)
    end
  end
end
