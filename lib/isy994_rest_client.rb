#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'rest-client'
require 'slack_notify'
require 'singleton'

class ISY994RestClient
  include Singleton

  def run_program(name:, command: :if)
    command = command.to_s.downcase.to_sym
    command = :if unless %i[ if then else ].include?(command)
    cmd = case command
    when :if
      'runIf'
    when :then
      'runThen'
    when :else
      'runElse'
    else
      'runIf'
    end
    if (attr = programs.find { |a| a['name'] == name })
      puts get("programs/#{attr['id']}/#{cmd}")['RestResponse']
    else
      STDERR.puts "Missing program #{name}, NOT running command #{command}"
    end
  rescue StandardError => e
    STDERR.puts e.message
  end

  def set_integer(name:, value:)
    if (attr = integer_variables.find { |a| a['name'] == name })
      puts get("vars/set/1/#{attr['id']}/#{value}")['RestResponse']
    else
      STDERR.puts "Missing integer variable #{name}, NOT setting value to #{value}"
    end
  rescue StandardError => e
    STDERR.puts e.message
  end

  def set_state(name:, value:)
    if (attr = state_variables.find { |a| a['name'] == name })
      get("vars/set/2/#{attr['id']}/#{value}")['RestResponse']
      puts "REST response : #{result['RestResponse'].to_json}"
    else
      STDERR.puts "Missing state variable #{name}, NOT setting value to #{value}"
    end
  rescue StandardError => e
    STDERR.puts e.message
  end

  private

  def programs
    @programs ||= get('programs?subfolders=true')['programs']['program'].select { |e| e['folder'] == 'false' }
  end

  def integer_variables
    @integer_variables ||= get('vars/definitions/1')['CList']['e']
  end

  def state_variables
    @state_variables ||= get('vars/definitions/2')['CList']['e']
  end

  def get(path)
    Hash.from_xml(RestClient.get("#{isy994_uri}/rest/#{path}"))
  rescue StandardError => e
    STDERR.puts e.message
  end

  def isy994_uri
    @isy994_uri ||= ENV['ISY994_URI'] if ENV['ISY994_URI'] && ENV['ISY994_URI'].length > 0
    @isy994_uri ||= ((Configuration.instance.config['action_handlers'] || {})['isy994'] || {})['uri']
    @isy994_uri ||= 'http://admin:admin@isy994-ems'
  end
end
