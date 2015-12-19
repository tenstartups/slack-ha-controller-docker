class SlackhookCommandHandler
  include WorkerThreadBase

  def initialize
    @action_handlers = (Configuration.instance.action_handlers.try(:to_h) || {}).reduce({}) do |hash, (_slug, attrs)|
      attrs[:actions].each { |k, v| hash[k] = [ActiveSupport::Inflector.constantize(attrs[:class_name]), v.to_sym] }
      hash
    end

    @work_queue = Queue.new
  end

  def enqueue(params)
    @work_queue.push(SlackMessage.new(params))
  end

  def do_work
    until @work_queue.empty?

      # Set the slack message thread variable
      slack_msg = @work_queue.pop
      Thread.current.thread_variable_set(:slack_message, slack_msg)

      # Check if the user is present
      if slack_msg.user_name.nil?
        slack_msg.error "No user specified for command `#{slack_msg.command}`!",
                        attributes: slack_msg.attributes
        next
      end

      # Check if the command is valid
      if ENV['SLACK_AUTH_COMMANDS'] && !ENV['SLACK_AUTH_COMMANDS'].split(',').any? { |c| c == slack_msg.command }
        slack_msg.error "Invalid command `#{slack_msg.command}` received from `#{slack_msg.user_name}`!",
                        attributes: slack_msg.attributes
        next
      end

      # Check if the message is authentic for this command
      auth_token = ENV["#{slack_msg.command.upcase.tr('-', '_')}_SLACK_AUTH_TOKEN"]
      if auth_token && slack_msg.token != auth_token
        slack_msg.error "Command `#{slack_msg.command}` from `#{slack_msg.user_name}` is not authentic!",
                        attributes: slack_msg.attributes
        next
      end

      # Check if the user is authorized for any command
      if ENV['SLACK_AUTH_USERS'] && !ENV['SLACK_AUTH_USERS'].split(',').any? { |u| [slack_msg.user_id, slack_msg.user_name].include?(u) }
        slack_msg.error "User `#{slack_msg.user_name}` is not authorized for any commands`!",
                        attributes: slack_msg.attributes
        next
      end

      # Check if the user is authorized for the specific command
      auth_users = ENV["#{slack_msg.command.upcase.tr('-', '_')}_SLACK_AUTH_USERS"]
      if auth_users && !auth_users.split(',').any? { |u| [slack_msg.user_id, slack_msg.user_name].include?(u) }
        slack_msg.error "User `#{slack_msg.user_name}` is not authorized for command `#{slack_msg.command}`!",
                        attributes: slack_msg.attributes
        next
      end

      # Look for matching command actions
      matching = (Configuration.instance.command_actions || []).select do |defn|
        defn['if'] && defn['if']['command'] == slack_msg.command &&
        (args = defn['if']['arguments']) == slack_msg.text_words[0..(args.length - 1)]
      end

      if matching.length > 0
        slack_msg.info "Received command `#{slack_msg.display}` from `#{slack_msg.user_name}`"
        matching.map { |e| e['then'] || [] }.each do |action_defns|
          action_defns.each do |action_defn|
            if action_defn.is_a?(String)
              action_class = @action_handlers[action_defn.to_sym][0]
              action_method = @action_handlers[action_defn.to_sym][1]
              action_class.instance.send(action_method)
            elsif action_defn.is_a?(Hash)
              action_defn.keys.each do |action|
                action_class = @action_handlers[action.to_sym][0]
                action_method = @action_handlers[action.to_sym][1]
                action_class.instance.send(action_method, **(action_defn[action].symbolize_keys))
              end
            end
          end
        end
      else
        slack_msg.error "Unknown command `#{slack_msg.display}` from `#{slack_msg.user_name}`",
                        attributes: slack_msg.attributes
        next
      end
    end
  end
end
