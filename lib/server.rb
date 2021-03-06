module Slackhook
  class Server
    include Singleton
    include LoggingHelper

    def start!
      threads = []

      # Start the logger loop
      threads << ConsoleLogger.instance.tap(&:start!)

      # Start the command handler
      threads << SlashCommandHandler.instance.tap(&:start!)

      # Start the build tools thread
      threads << TaskHandler.instance.tap(&:start!)

      # Start the API REST server
      threads << RestServer.instance.tap(&:start!)

      # Trap CTRL-C and SIGTERM
      trap('INT') do
        warn 'CTRL-C detected, waiting for all threads to exit gracefully...'
        threads.reverse_each(&:quit!)
        exit(0)
      end
      trap('TERM') do
        error 'Kill detected, waiting for all threads to exit gracefully...'
        threads.reverse_each(&:quit!)
        exit(1)
      end

      warn 'Press CTRL-C at any time to stop all threads and exit'

      # Wait on threads
      threads.each(&:wait!)
    end
  end
end
