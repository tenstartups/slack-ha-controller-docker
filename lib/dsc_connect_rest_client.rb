#!/usr/bin/env ruby
require 'rest-client'
require 'singleton'

class DSCConnectRestClient
  include Singleton

  def disarm
    puts RestClient.post("#{dsc_connect_uri}/disarm?code=1234")
  rescue StandardError => e
    STDERR.puts e.message
  end

  def arm_stay
    puts RestClient.post("#{dsc_connect_uri}/arm_stay")
  rescue StandardError => e
    STDERR.puts e.message
  end

  def arm_away
    puts RestClient.post("#{dsc_connect_uri}/arm_away")
  rescue StandardError => e
    STDERR.puts e.message
  end

  private

  def dsc_connect_uri
    @dsc_connect_uri ||= ENV['DSC_CONNECT_URI'] if ENV['DSC_CONNECT_URI'] && ENV['DSC_CONNECT_URI'].length > 0
    @dsc_connect_uri ||= ((Configuration.instance.config['action_handlers'] || {})['dsc_connect'] || {})['URI']
    @dsc_connect_uri ||= 'http://dsc-connect'
  end
end
