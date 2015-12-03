require 'singleton'

class CommandActionHandler
  include Singleton

  def initialize
    @action_handlers = (Configuration.instance.config['action_handlers'] || []).reduce({}) do |hash, (_slug, attrs)|
      attrs['actions'].each { |k, v| hash[k] = [ActiveSupport::Inflector.constantize(attrs['class_name']), v.to_sym] }
      hash
    end
  end

  def run(*args)
    matching = Configuration.instance.config['command_actions'].select do |defn|
      defn['if'] && defn['if'].all? { |e| e.any? { |k, v| args.send(:[], k.to_i) == v } }
    end
    STDERR.puts "Unknown command" and return if matching == []
    matching.map { |e| e['then'] }.each do |action_defns|
      action_defns.each do |action_defn|
        action_defn.each do |(action, attrs)|
          action_class = @action_handlers[action][0]
          action_method = @action_handlers[action][1]
          action_class.instance.send(action_method, **(attrs.symbolize_keys))
        end
      end
    end
  end
end
