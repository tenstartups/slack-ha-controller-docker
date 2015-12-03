#!/usr/bin/env ruby

Dir['/usr/local/lib/ruby/*.rb'].each { |f| load f }

CommandActionHandler.instance.run(*ARGV)
