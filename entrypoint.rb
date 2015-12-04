#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'awesome_print'
require 'pry'

Dir[File.join(ENV['RUBYLIB'], '*.rb')].each { |f| require f }

case ARGV[0]
when 'server'
  SlackhookServer.start!
when 'pry'
  binding.pry
else
  exec(*ARGV) if ARGV.size > 0
end
