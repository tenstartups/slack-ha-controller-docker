module Slackhook
  module LoggingHelper
    %i( debug info warn error success ).each do |severity|
      define_method severity do |message, source_id: nil|
        send(:log, severity: severity, message: message)
      end
    end

    def log(severity:, message:)
      # Construct a source id for the log message
      source_id = self.class.name.split('::').last

      # Log to the console
      ConsoleLogger.instance.send(:log,
        source_id: source_id,
        severity: severity,
        message: message
      )

      # Append to the task log if one is in play
      if (log_file = Thread.current.thread_variable_get(:log_file))
        line = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} | #{source_id[0..19].ljust(20)} | #{message}\n"
        File.open(log_file, 'a') { |f| f.write(line) }
      end
    end
  end
end
