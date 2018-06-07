require 'json'
require 'rest-client'
require_relative 'cfme_service'

class DeProvision
  def initialize(options, parameters, os_instance_id)
    @url            = options[:url]
    @user           = options[:user]
    @password       = options[:password]
    @verify_ssl     = options[:verify_ssl]
    @parameters     = parameters
    @api_url        = build_api_url(@url)
    @service        = CFMEService.new(options).find(os_instance_id)
  end

  def execute
    raise "No matching service found" unless @service
    rest_return = RestClient::Request.execute(:method => :post,
                                              :url    => @api_url + "/services",
                                              :user   => @user,
                                              :password => @password,
                                              :headers => {:accept => :json},
                                              :payload => body.to_json,
                                              :verify_ssl => @verify_ssl)
    JSON.parse(rest_return.body)['results'][0]['href'] 
  end

  def body
    { 'action'   => request_action,
      'resource' => {'href' => @service['href'] }}
  end

  def request_action
    deprovision_task? ? 'request_retire' : 'retire'
  end

  def deprovision_task?
    @service[:actions].include?('request_retire')
  end

  def build_api_url(url)
    raise "url not specified" unless url
    parts = URI.parse(url)
    parts.path = "/api"
    parts.to_s
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  options[:user] = "admin"
  options[:password] = "xxxxxx"
  options[:verify_ssl] = false
  options[:url] = 'https://cfmeserver/api'
  instance_id = "431ebff6-15b2-4d93-a5e2-346506962d5a"
  instance_id = "aa414f1a-7099-454d-949b-9012a463dfe1"
  puts DeProvision.new(options, {}, instance_id).execute
end
