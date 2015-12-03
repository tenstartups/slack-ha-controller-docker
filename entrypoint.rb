#!/usr/bin/env ruby
require 'awesome_print'
require 'pry'
require 'configuration'

ENV['WEBHOOK_CONFIG'] = '/etc/webhook/hooks.json'

Configuration.instance

case ARGV[0]
when 'webhook'
  exec 'webhook', '-hooks', ENV['WEBHOOK_CONFIG'], '--verbose'
when 'pry'
  binding.pry
else
  exec(*ARGV) if ARGV.size > 0
end
