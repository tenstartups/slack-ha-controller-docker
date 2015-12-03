require 'fileutils'
require 'singleton'
require 'yaml'

class Configuration
  include Singleton

  attr_reader :config

  def initialize
    default_config = File.join(File.dirname(__FILE__), 'config.yml')
    if ENV['CONFIG_FILE'] && !File.exist?(ENV['CONFIG_FILE'])
      warn "Copying default configuration to #{ENV['CONFIG_FILE']}"
      FileUtils.mkdir_p(File.dirname(ENV['CONFIG_FILE']))
      FileUtils.cp(default_config, ENV['CONFIG_FILE'])
    end
    @config = YAML.load_file(ENV['CONFIG_FILE']) if ENV['CONFIG_FILE'] && File.exist?(ENV['CONFIG_FILE'])
    @config ||= YAML.load_file(default_config)
  end
end
