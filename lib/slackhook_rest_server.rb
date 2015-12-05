require 'json'
require 'rest-client'
require 'sinatra/base'
require 'configuration'

class SlackhookRestServer
  include WorkerThreadBase

  def do_work
    SinatraApp.run!
  end

  def quit!
    SinatraApp.quit!
    super
  end

  def bind_address
    Configuration.instance.rest_server.try(:bind_address) || '0.0.0.0'
  end

  def bind_port
    Configuration.instance.rest_server.try(:bind_port) || 8080
  end

  private

  def thread_ready
    JSON.parse(RestClient.get("http://#{bind_address}:#{bind_port}/start_check"))['status'] == 'ok'
  rescue Exception => e
    false
  end
end

class SinatraApp < Sinatra::Base
  set :server, :puma

  configure do
    set :environment, 'production'
    set :bind, Configuration.instance.bind_address || '0.0.0.0'
    set :port, Configuration.instance.bind_port || '8080'
    set :run, true
    set :threaded, true
    set :traps, false
  end

  get '/start_check' do
    content_type :json
    { status: 'ok' }.to_json
  end

  post '/:command' do
    SlackhookCommandHandler.instance.enqueue(params)
    Configuration.instance.rest_server.try(:ack_message) || 'ok'
  end
end
