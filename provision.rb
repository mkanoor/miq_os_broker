require 'json'
require 'rest-client'

class Provision
  def initialize(options, parameters, os_instance_id)
    @url            = options[:url]
    @user           = options[:user]
    @password       = options[:password]
    @verify_ssl     = options[:verify_ssl]
    @parameters     = parameters
    @os_instance_id = os_instance_id
  end

  def execute
    rest_return = RestClient::Request.execute(:method => :post,
                                              :url    => @parameters['service_catalog_href'],
                                              :user   => @user,
                                              :password => @password,
                                              :headers => {:accept => :json},
                                              :payload => body.to_json,
                                              :verify_ssl => @verify_ssl)
    #JSON.parse(rest_return)['results'][0]['id'] 
    JSON.parse(rest_return)['results'][0]['href'] 
  end

  def body
    { 'action'   => 'order',
      'resource' => resource}
  end

  def resource
    @parameters
  end
end

if __FILE__ == $PROGRAM_NAME
  parameters = {"text_box_1" => "vm00015", 
                "text_box_2" => 25,
                "href"       => "https://cfmeserver/api/service_templates/1",
                "service_catalog_href" => "https://cfmeserver/api/service_catalogs/1/service_templates"}
  os_instance_id = 54
  options = {:url        => 'https://cfmeserver',
             :user       => 'admin',
             :password   => 'xxxxx',
             :verify_ssl => false}
  puts Provision.new(options, parameters, os_instance_id).execute
end
