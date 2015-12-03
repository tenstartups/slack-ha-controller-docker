#!/usr/bin/env ruby
require 'awesome_print'

Dir['/usr/local/lib/ruby/*.rb'].each { |f| load f }

CommandActionHandler.instance.run
