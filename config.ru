# frozen_string_literal: true

require_relative 'lib/common'
require_relative 'lib/catalog'
require_relative 'lib/provision'
require_relative 'lib/request_status'
require 'byebug'

class Servicebroker < Sinatra::Base

  CACHE = {}

  get '/v2/catalog' do
    Catalog.new.get_catalog.to_json
  end

  get '/v2/service_instances/:instance_id/last_operation' do
    @id = params['instance_id']
    @operation = params['operation']

    options = {:url        => 'https://10.8.198.182',
               :user       => 'admin',
               :password   => 'smartvm',
               :verify_ssl => false}
    request_href = @operation.split('create_')[1]
    puts request_href

    result = RequestStatus.new(options, request_href).status
    puts result
    begin
      if @operation.start_with?('create')
        if result['request_state'] == 'finished'
          {
            state: 'succeeded',
            description: result['message']
          }.to_json
        else
          {
            state: 'in progress',
            description: result['message']
          }.to_json
        end
      elsif @operation.start_with?('destroy')
        if K8s.undeployed?(CACHE[@id], @id)
          {
            state: 'succeeded',
            description: 'Workshop content is undeployed.'
          }.to_json
        else
          {
            state: 'in progress',
            description: 'Still undeploying the workshop content.'
          }.to_json
        end
      end
    rescue => e
      {
        state: 'failed',
        description: "Operation failed: #{e.message}"
      }.to_json
    end
  end

  put '/v2/service_instances/:instance_id' do
    @id = params['instance_id']
    @data = JSON.load(request.body.read)
    puts @data.inspect
    @plan = @data['plan_id']
    @parameters = @data['parameters']
    @context = @data['context']

    CACHE[@id] = { namespace: @context['namespace'] }

    
    options = {:url        => 'https://10.8.198.182',
               :user       => 'admin',
               :password   => 'smartvm',
               :verify_ssl => false}
    miq_request_href = Provision.new(options, @parameters, @id).provision


    status 202

    { operation: "create_#{miq_request_href}" , miq_request_href: miq_request_href}.to_json
  end

  delete '/v2/service_instances/:instance_id' do
    @id = params['instance_id']

    K8s.undeploy(CACHE[@id][:namespace], @id)

    status 202

    { operation: "destroy_#{@id}" }.to_json
  end

  patch '/v2/service_instances/:instance_id' do
    status 404
    {}.to_json
  end

  put '/v2/service_instances/:instance_id/service_bindings/:binding_id' do
    status 404
    {}.to_json
  end

  delete '/v2/service_instances/:instance_id/service_bindings/:binding_id' do
    status 404
    {}.to_json
  end

end

run Servicebroker
