# frozen_string_literal: true

require_relative 'lib/common'
require_relative 'lib/catalog'
require_relative 'lib/provision'
require_relative 'lib/operation_status'
require_relative 'lib/custom_attribute'
require_relative 'lib/deprovision'
require_relative 'lib/request_options'

class Servicebroker < Sinatra::Base

  get '/v2/catalog' do
    Catalog.new(options).get_catalog.to_json
  end

  get '/v2/service_instances/:instance_id/last_operation' do
    @id = params['instance_id']
    @operation = params['operation']

    begin
      if @operation.start_with?('create')
        href = @operation.split('create_')[1]
        puts href
        result = OperationStatus.new(options, href).status
        puts result
        if result['state'] == 'succeeded'
          os_attrs = RequestOptions.new(options.merge(:request_href => href)).get_options['os_attrs']
          CustomAttribute.new(options.merge(:request_href => href)).set_attributes(os_attrs)
        end
        result.to_json
      elsif @operation.start_with?('destroy')
        href = @operation.split('destroy_')[1]
        puts href

        result = OperationStatus.new(options, href).status
        puts result
        result.to_json
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
    @namespace = @context['namespace']

    miq_request_href = Provision.new(options, @parameters, @id).execute

    os_options = {'os_attrs' => { 'openshift_instance_id' => @id,
                                  'service_id'            => @data['service_id'],
                                  'parameters'            => @parameters,
                                  'plan_id'               => @data['plan_id'] } }
    RequestOptions.new(options.merge(:request_href => miq_request_href)).set_options(os_options)
    status 202

    { operation: "create_#{miq_request_href}" , miq_request_href: miq_request_href}.to_json
  end

  delete '/v2/service_instances/:instance_id' do
    @id = params['instance_id']

    status 202
    href = DeProvision.new(options, {}, @id).execute


    { operation: "destroy_#{href}" }.to_json
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

  def options
    { :url        => 'https://cfmeserver',
      :user       => 'admin',
      :password   => 'xxxxxxx',
      :verify_ssl => false }
  end
end

run Servicebroker
