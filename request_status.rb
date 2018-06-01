require 'json'
require 'rest-client'
require 'byebug'
class RequestStatus
  def initialize(options, request_href)
    @url            = options[:url]
    @user           = options[:user]
    @password       = options[:password]
    @verify_ssl     = options[:verify_ssl]
    @href           = request_href
  end

  def status
    rest_return = RestClient::Request.execute(:method => :get,
                                              :url    => @href,
                                              :user   => @user,
                                              :password => @password,
                                              :headers => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    result = JSON.parse(rest_return)
    {
     'status'        => result['status'], 
     'message'       => result['message'],
     'request_state' => result['request_state'],
     'approval_state' => result['approval_state']
    }
  end
end

options = {:url        => 'https://10.8.198.182',
           :user       => 'admin',
           :password   => 'smartvm',
           :verify_ssl => false}
request_href="https://10.8.198.182/api/service_requests/7"
#puts RequestStatus.new(options, request_href).status
