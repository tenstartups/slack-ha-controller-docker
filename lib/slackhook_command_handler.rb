class SlackhookCommandHandler
  include WorkerThreadBase

  def initialize
    @action_handlers = (Configuration.instance.action_handlers.try(:to_h) || {}).reduce({}) do |hash, (_slug, attrs)|
      attrs['actions'].each { |k, v| hash[k] = [ActiveSupport::Inflector.constantize(attrs['class_name']), v.to_sym] }
      hash
    end

    @work_queue = Queue.new
  end

  def enqueue(params)
    @work_queue.push(SlackbotMessage.new(params))
  end

  def do_work
    until @work_queue.empty?

      slackbot_msg = @work_queue.pop

      # Check if the user is present
      if slackbot_msg.user_name.nil?
        slackbot_msg.error "No user specified for command `#{slackbot_msg.command}`!",
                           attributes: slackbot_msg.attributes
        next
      end

      # Check if the command is valid
      if ENV['SLACK_AUTH_COMMANDS'] && !ENV['SLACK_AUTH_COMMANDS'].split(',').any? { |c| c == slackbot_msg.command }
        slackbot_msg.error "Invalid command `#{slackbot_msg.command}` received from `#{slackbot_msg.user_name}`!",
                           attributes: slackbot_msg.attributes
        next
      end

      # Check if the message is authentic for this command
      auth_token = ENV["#{slackbot_msg.command.upcase.gsub(/-/, '_')}_SLACK_AUTH_TOKEN"]
      if auth_token && slackbot_msg.token != auth_token
        slackbot_msg.error "Command `#{slackbot_msg.command}` from `#{slackbot_msg.user_name}` is not authentic!",
                           attributes: slackbot_msg.attributes
        next
      end

      # Check if the user is authorized for any command
      if ENV["SLACK_AUTH_USERS"] && !ENV["SLACK_AUTH_USERS"].split(',').any? { |u| [slackbot_msg.user_id, slackbot_msg.user_name].include?(u) }
        slackbot_msg.error "User `#{slackbot_msg.user_name}` is not authorized for any commands`!",
                           attributes: slackbot_msg.attributes
        next
      end

      # Check if the user is authorized for the specific command
      auth_users = ENV["#{slackbot_msg.command.upcase.gsub(/-/, '_')}_SLACK_AUTH_USERS"]
      if auth_users && !auth_users.split(',').any? { |u| [slackbot_msg.user_id, slackbot_msg.user_name].include?(u) }
        slackbot_msg.error "User `#{slackbot_msg.user_name}` is not authorized for command `#{slackbot_msg.command}`!",
                           attributes: slackbot_msg.attributes
        next
      end

      # Look for matching command actions
      matching = (Configuration.instance.command_actions || []).select do |defn|
        defn['if'] && defn['if']['command'] == slackbot_msg.command && defn['if']['arguments'] == slackbot_msg.text_words
      end

      if matching.length > 0
        slackbot_msg.info "Received command `#{slackbot_msg.display}` from `#{slackbot_msg.user_name}`"
        matching.map { |e| e['then'] }.each do |action_defns|
          action_defns.each do |action_defn|
            if action_defn.is_a?(String)
              action_class = @action_handlers[action_defn][0]
              action_method = @action_handlers[action_defn][1]
              action_class.instance.send(action_method)
            elsif action_defn.is_a?(Hash)
              action_defn.keys.each do |action|
                action_class = @action_handlers[action][0]
                action_method = @action_handlers[action][1]
                action_class.instance.send(action_method, **(action_defn[action].symbolize_keys))
              end
            end
          end
        end
      else
        slackbot_msg.error "Unknown command `#{slackbot_msg.display}` from `#{slackbot_msg.user_name}`",
                           attributes: slackbot_msg.attributes
        next
      end
    end
  end
end
