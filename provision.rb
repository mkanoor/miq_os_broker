require 'json'
require 'rest-client'
require 'byebug'
class Provision
  def initialize(options, parameters, os_instance_id)
    @url            = options[:url]
    @user           = options[:user]
    @password       = options[:password]
    @verify_ssl     = options[:verify_ssl]
    @parameters     = parameters
    @os_instance_id = os_instance_id
  end

  def provision
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

parameters = {"text_box_1" => "vm00015", 
              "text_box_2" => 25,
              "href"       => "https://10.8.198.182/api/service_templates/1",
              "service_catalog_href" => "https://10.8.198.182/api/service_catalogs/1/service_templates"}
os_instance_id = 54
options = {:url        => 'https://10.8.198.182',
           :user       => 'admin',
           :password   => 'smartvm',
           :verify_ssl => false}
#Provision.new(options, parameters, os_instance_id).provision
