#!/usr/bin/env ruby
require 'rest-client'
require 'singleton'

class DSCConnectRestClient
  include Singleton

  def disarm(code:)
    RestClient.post("#{dsc_connect_uri}/disarm", code: code)
  end

  def arm_stay
    RestClient.post("#{dsc_connect_uri}/arm_stay", {})
  end

  def arm_away
    RestClient.post("#{dsc_connect_uri}/arm_away", {})
  end

  private

  def dsc_connect_uri
    @dsc_connect_uri ||= ENV['DSC_CONNECT_URI'] if ENV['DSC_CONNECT_URI'] && ENV['DSC_CONNECT_URI'].length > 0
    @dsc_connect_uri ||= ((Configuration.instance.config['action_handlers'] || {})['dsc_connect'] || {})['uri']
    @dsc_connect_uri ||= 'http://dsc-connect'
  end
end
