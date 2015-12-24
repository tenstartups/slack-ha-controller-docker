require 'json'
require 'rest-client'
require 'sinatra/base'
require 'configuration'

module Slackhook
  class RestServer
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
    rescue StandardError
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

    get '/queued' do
      content_type :json
      TaskHandler.instance.queued
    end

    get '/task_log/?:log_file?' do
      content_type :text
      log_file = if params[:log_file]
                   File.join(TaskHandler.instance.log_directory, params[:log_file])
                 else
                   TaskHandler.instance.log_file
                 end
      if log_file.nil?
        "No log file found.\n"
      elsif File.exist?(log_file)
        File.read(log_file)
      else
        "Log file #{params[:log_file]} not found.\n"
      end
    end

    post '/:command' do
      SlashCommandHandler.instance.enqueue(params)
      Configuration.instance.rest_server.try(:ack_message) || 'ok'
    end
  end
end
