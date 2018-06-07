require 'rest-client'
require 'json'

class CustomAttribute
  def initialize(options = {})
    @url           = options[:url]
    @user          = options[:user]
    @password      = options[:password]
    @verify_ssl    = options[:verify_ssl]
    @request_href  = options[:request_href]
    @api_url       = build_api_url(@url)
  end

  def service_href
    task_url = "#{@request_href}/request_tasks?filter[]=type=ServiceTemplateProvisionTask&expand=resources"
    rest_return = RestClient::Request.execute(:method => :get,
                                              :url    => task_url,
                                              :user   => @user,
                                              :password => @password,
                                              :headers  => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    service_id = JSON.parse(rest_return.body)['resources'][0]['destination_id']
    @api_url + "/services/" + service_id.to_s
  end

  def set_attributes(attrs)
    service_url = "#{service_href}/custom_attributes"
    puts "Setting custom attribute #{attrs}"
    resources = []
    attrs.each { |k, v| resources << { 'name' => k, 'value' => v } }

    body = { 'action' => 'add', 'resources' => resources }
    response = RestClient::Request.new(:method => :post,
                                       :url => service_url,
                                       :user   => @user,
                                       :password => @password,
                                       :verify_ssl => @verify_ssl,
                                       :payload => body.to_json).execute
    parsed_data = JSON.parse(response.body)
    puts parsed_data 
  end

  private

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
  instance_id = "123-45678-91234-12348"
  options[:request_href] = 'https://cfmeserver/api/requests/2'
  puts CustomAttribute.new(options).set_attributes('openshift_instance_id' => instance_id,
                                                   "a"                     => 1,
                                                   "b"                     => 2)
end
