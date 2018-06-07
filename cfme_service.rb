require 'rest-client'
require 'json'

class CFMEService
  def initialize(options = {})
    @url           = options[:url]
    @user          = options[:user]
    @password      = options[:password]
    @verify_ssl    = options[:verify_ssl]
    @instance_id   = options[:instance_id]
    @api_url       = build_api_url(@url)
  end

  def find(instance_id)
    result = get_all_services 
    actions = result['actions'].collect { |action| action['name'] }
    result['resources'].each do |item|
      item.fetch('custom_attributes', []).each do |cust_attr|
        if cust_attr['name'] = 'openshift_instance_id' && cust_attr['value'] == instance_id
          return item.merge(:actions => actions)
        end
      end
    end
    nil
  end

  private

  def get_all_services
    query = "/services?expand=custom_attributes,resources&attributes=name"
    rest_return = RestClient::Request.execute(:method => :get,
                                              :url    => @api_url + query,
                                              :user   => @user,
                                              :password => @password,
                                              :headers  => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    JSON.parse(rest_return.body)
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
  options[:password] = "XXXXXXX"
  options[:verify_ssl] = false
  options[:url] = 'https://cfmeserver/api'
  instance_id = "431ebff6-15b2-4d93-a5e2-346506962d5a"
  puts CFMEService.new(options).find(instance_id)
end
