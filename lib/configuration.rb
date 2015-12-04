require 'delegate'
require 'fileutils'
require 'json'
require 'recursive-open-struct'
require 'singleton'
require 'yaml'

class Configuration < SimpleDelegator
  include Singleton

  def initialize
    default_config = File.join(File.dirname(__FILE__), 'config.yml')
    unless ENV['CONFIG_FILE'].nil? || File.exist?(ENV['CONFIG_FILE'])
      STDERR.puts "Copying default configuration to #{ENV['CONFIG_FILE']}"
      FileUtils.mkdir_p(File.dirname(ENV['CONFIG_FILE']))
      FileUtils.cp(default_config, ENV['CONFIG_FILE'])
    end
    config = YAML.load_file(ENV['CONFIG_FILE']) if ENV['CONFIG_FILE'] && File.exist?(ENV['CONFIG_FILE'])
    config ||= YAML.load_file(default_config)
    super(RecursiveOpenStruct.new(config))
  end

  def method_missing(*_)
    nil
  end

  def respond_to_missing?(*_)
    true
  end
end
