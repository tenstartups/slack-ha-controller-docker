require 'fileutils'
require 'json'
require 'singleton'
require 'yaml'

class Configuration
  include Singleton

  attr_reader :config

  def initialize

    # Initialize the application configuration
    default_config = File.join(File.dirname(__FILE__), 'config.yml')
    unless ENV['CONFIG_FILE'].nil? || File.exist?(ENV['CONFIG_FILE'])
      STDERR.puts "Copying default configuration to #{ENV['CONFIG_FILE']}"
      FileUtils.mkdir_p(File.dirname(ENV['CONFIG_FILE']))
      FileUtils.cp(default_config, ENV['CONFIG_FILE'])
    end
    @config = YAML.load_file(ENV['CONFIG_FILE']) if ENV['CONFIG_FILE'] && File.exist?(ENV['CONFIG_FILE'])
    @config ||= YAML.load_file(default_config)

    # Initialize the hooks configuration
    unless ENV['WEBHOOK_CONFIG'].nil? || File.exist?(ENV['WEBHOOK_CONFIG'])
      STDERR.puts "Creating hooks configuration #{ENV['WEBHOOK_CONFIG']}"
      FileUtils.mkdir_p(File.dirname(ENV['WEBHOOK_CONFIG']))
      config = (ENV['SLACK_AUTH_COMMANDS'] || '').split(',').map do |command|
        {
          'id' => command,
          'execute-command' => '/usr/local/bin/webhook-command',
          'response-message' => 'ok',
          'include-command-output-in-response' => false,
          'pass-arguments-to-command' => [
            {
              'source' => 'entire-payload'
            }
          ]
        }
      end
      File.open(ENV['WEBHOOK_CONFIG'], 'w') { |f| f.write(config.to_json) }
    end
  end
end
