#!/usr/bin/env ruby
require 'rest-client'
require 'singleton'

class ISY994RestClient
  include Singleton
  include LoggingHelper

  def run_program(name:, branch: :if)
    branch = branch.to_s.downcase.to_sym
    branch = :if unless %i[ if then else ].include?(branch)
    cmd = case branch
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
      info "Running program #{name}, #{branch} branch"
      result = get("programs/#{attr['id']}/#{cmd}")
      info "Result : #{result}"
    else
      warn "Missing program #{name}, NOT running #{branch} branch"
    end
  end

  def set_integer(name:, value:)
    if (attr = integer_variables.find { |a| a['name'] == name })
      info "Setting integer variable #{name} to #{value}"
      get("vars/set/1/#{attr['id']}/#{value}")
      info "Result : #{result}"
    else
      warn "Missing integer variable #{name}, NOT setting value to #{value}"
    end
  end

  def set_state(name:, value:)
    if (attr = state_variables.find { |a| a['name'] == name })
      info "Setting state variable #{name} to #{value}"
      result = get("vars/set/2/#{attr['id']}/#{value}")
      info "Result : #{result}"
    else
      warn "Missing state variable #{name}, NOT setting value to #{value}"
    end
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
  end

  def isy994_uri
    @isy994_uri ||= ENV['ISY994_URI'] if ENV['ISY994_URI'] && ENV['ISY994_URI'].length > 0
    @isy994_uri ||= Configuration.instance.action_handlers.try(:isy994).try(:uri)
    @isy994_uri ||= 'http://admin:admin@isy994-ems'
  end
end
