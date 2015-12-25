module Slackhook
  class SlashCommandHandler
    include WorkerThreadBase

    def initialize
      @action_handlers = (Configuration.instance.action_handlers.try(:to_h) || {}).reduce({}) do |hash, (_slug, attrs)|
        attrs = attrs.symbolize_keys
        attrs[:actions].each { |k, v| hash[k.to_sym] = [ActiveSupport::Inflector.constantize(attrs[:class_name]), v.to_sym] }
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
        slack_message = @work_queue.pop
        Thread.current.thread_variable_set(:slack_message, slack_message)

        # Check if the user is present
        if slack_message.user_name.nil?
          slack_message.error "No user specified for command `#{slack_message.command}`!",
                              attributes: slack_message.attributes
          next
        end

        # Check if the command is valid
        unless Configuration.instance.commands.send(slack_message.command)
          slack_message.error "Invalid command `#{slack_message.command}` received from `#{slack_message.user_name}`!",
                              attributes: slack_message.attributes
          next
        end

        # Check if the message is authentic for this command
        auth_token = Configuration.instance.commands.send(slack_message.command).try(:slack_auth_token)
        if auth_token && slack_message.token != auth_token
          slack_message.error "Command `#{slack_message.command}` from `#{slack_message.user_name}` is not authentic!",
                              attributes: slack_message.attributes
          next
        end

        # Check if the user is authorized for any command
        auth_users = Configuration.instance.slack_auth_users
        if auth_users && !auth_users.any? { |u| [slack_message.user_id, slack_message.user_name].include?(u) }
          slack_message.error "User `#{slack_message.user_name}` is not authorized for any commands!",
                              attributes: slack_message.attributes
          next
        end

        # Check if the user is authorized for this command
        auth_users = Configuration.instance.commands.send(slack_message.command).try(:slack_auth_users)
        if auth_users && !auth_users.any? { |u| [slack_message.user_id, slack_message.user_name].include?(u) }
          slack_message.error "User `#{slack_message.user_name}` is not authorized for `#{slack_message.command}` command!",
                              attributes: slack_message.attributes
          next
        end

        # Look for matching command actions
        matching = (Configuration.instance.command_actions || []).select do |defn|
          defn['conditions'] && defn['conditions']['command'] == slack_message.command &&
          (args = defn['conditions']['arguments']) == slack_message.text_words[0..(args.length - 1)]
        end

        if matching.length > 0
          slack_message.info "Received command `#{slack_message.display}` from `#{slack_message.user_name}`"
          matching.each { |defn| execute_actions(slack_message.text_words, defn) }
        else
          slack_message.error "Unknown command `#{slack_message.display}` from `#{slack_message.user_name}`",
                              attributes: slack_message.attributes
          next
        end
      end
    end

    def execute_actions(command_args, command_defn)
      actions = command_defn['actions'].reduce([]) do |a, action_defn|
        if action_defn.is_a?(String)
          a << {
            action_class: @action_handlers[action_defn.to_sym][0],
            action_method: @action_handlers[action_defn.to_sym][1],
            action_arguments: {}
          }
        elsif action_defn.is_a?(Hash)
          action_defn.keys.each do |action|
            arguments = action_defn[action].keys.reduce({}) do |args, name|
              value = action_defn[action][name]
              if (match = /^\$(\d+)$/.match(value.to_s))
                value = command_args.send(:[], match[1].to_i - 1) ||
                        command_defn['default_arguments'].send(:[], match[1].to_i)
              end
              if (match = /^\$\*$/.match(value.to_s))
                value = command_args
              end
              if (match = /^(?<lookup_name>.+)_lookup_(?<lookup_value>.+)$/.match(name))
                name = match[:lookup_value]
                Configuration.instance.lookup.send(:"#{match[:lookup_name]}").each do |lookup|
                  next unless lookup['patterns'].any? { |p| Regexp.new(p).match(value) }
                  value = lookup['params'][name]
                  break
                end
              end
              args[name.to_sym] = value
              args
            end
            a << {
              action_class: @action_handlers[action.to_sym][0],
              action_method: @action_handlers[action.to_sym][1],
              action_arguments: arguments
            }
          end
        end
        a
      end
      TaskHandler.instance.execute_task(command_args, actions, command_defn['task_properties'])
    end
  end
end
