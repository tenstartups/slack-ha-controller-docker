require 'json'
require 'sinatra/base'
require 'configuration'

class SlackhookServer < Sinatra::Base
  set :server, :puma

  configure do
    set :environment, 'production'
    set :bind, Configuration.instance.bind_address || '0.0.0.0'
    set :port, Configuration.instance.bind_port || '8080'
    set :run, true
    set :threaded, true
    set :traps, true
  end

  post '/:command' do
    SlackhookHandler.instance.run(params)
    'ok'
  end
end
