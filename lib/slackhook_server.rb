class SlackhookServer
  include Singleton

  def start!
    threads = []

    # Start the logger loop
    threads << ConsoleLogger.instance.tap(&:start!)

    # Start the command handler
    threads << SlackhookCommandHandler.instance.tap(&:start!)

    # Start the API REST server
    threads << SlackhookRestServer.instance.tap(&:start!)

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
