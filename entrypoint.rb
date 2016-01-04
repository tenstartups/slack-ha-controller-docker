#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'awesome_print'
require 'pry'

# Require all library files
%w( logging_helper worker_thread_base action/base ).each do |file_name|
  require "#{ENV['RUBYLIB']}/#{file_name}.rb"
end
Dir[File.join(ENV['RUBYLIB'], '**/*.rb')].each { |f| require f }

Thread.abort_on_exception = true
$stdout.sync = true

case ARGV[0]
when 'server'
  Slackhook::Server.instance.start!
when 'pry'
  binding.pry
else
  exec(*ARGV) if ARGV.size > 0
end
