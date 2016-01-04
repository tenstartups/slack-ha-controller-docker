module Slackhook
  class TaskHandler
    include WorkerThreadBase

    def initialize
      @task_queue = Queue.new
      @process_ids = Array.new
    end

    def execute_task(command_args, actions, properties)
      properties ||= {}
      task_proc = lambda do
        init_slack_notifier(properties['slack_notifier'])
        init_log_file(command_args)
        begin
          slack_notifier.info "Starting command `#{command_args.join(' ')}`"
          Dir.mktmpdir do |dir|
            Dir.chdir(dir)
            actions.each do |action|
              action[:action_class].instance.send(action[:action_method], **action[:action_arguments])
            end
          end
          slack_notifier.success "Finished command `#{command_args.join(' ')}`"
        rescue Slackhook::Action::Error => e
          slack_notifier.error "Error running command `#{command_args.join(' ')}`"
        end
      end
      if properties['background'] == true
        @task_queue.push(arguments: command_args, timestamp: Time.now, proc: task_proc)
      else
        task_proc.call
      end
    end

    def do_work
      until @task_queue.empty?
        task = @task_queue.pop
        break if quit_thread?
        task[:proc].call
      end
    end

    def log_directory
      ENV['TASK_LOG_DIRECTORY'] || '/var/log'
    end

    def log_file
      Thread.current.thread_variable_get(:log_file)
    end

    def log_file_url
      "#{Configuration.instance.rest_server.try(:url_host)}/task_log/#{File.basename(log_file)}"
    end

    def quit!
      @process_ids.each { |pid| Process.kill('HUP', pid) rescue nil }
      super
    end

    private

    def slack_notifier
      Thread.current.thread_variable_get(:slack_notifier)
    end

    def init_slack_notifier(properties = {})
      properties ||= {}
      Thread.current.thread_variable_set(
        :slack_notifier,
        SlackNotifier.new(**properties.symbolize_keys)
      )
    end

    def init_log_file(arguments)
      FileUtils.mkdir_p(log_directory)
      Thread.current.thread_variable_set(
        :log_file,
        File.join(
          log_directory,
          "#{arguments.join('_')}_#{Time.now.strftime('%Y%m%d%H%M%S')}.log"
        )
      )
    end
  end
end
