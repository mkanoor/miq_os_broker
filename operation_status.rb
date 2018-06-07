require 'json'
require 'rest-client'
require 'byebug'
class OperationStatus
  def initialize(options, href)
    @url            = options[:url]
    @user           = options[:user]
    @password       = options[:password]
    @verify_ssl     = options[:verify_ssl]
    @href           = href
  end

  def status
    rest_return = RestClient::Request.execute(:method => :get,
                                              :url    => @href,
                                              :user   => @user,
                                              :password => @password,
                                              :headers => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    result = JSON.parse(rest_return)
    /\/services\//.match(@href).nil? ? task_status(result) : service_retirement_status(result)
  end

  def task_status(result)
    {
      'state' => result['request_state'] == 'finished' ? task_errors(result) : 'in progress',
      'description' => result['message']
    }
  end

  def task_errors(result)
    result['status'] == 'Error'? "failed" : 'succeeded'
  end

  def service_retirement_status(result)
    {
      'state' => %w(retired error).include?(result['retirement_state']) ? retirement_errors(result) : 'in progress',
      'description' => result['retirement_state']
    }
  end

  def retirement_errors(result)
    result['retirement_state'] == 'error' ? 'failed' : 'succeeded'
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {:url        => 'https://cfmeserver',
             :user       => 'admin',
             :password   => 'xxxxx',
             :verify_ssl => false}
  href="https://cfmeserver/api/service_requests/7"
  puts OperationStatus.new(options, href).status
  href="https://cfmeserver/api/services/6"
  puts OperationStatus.new(options, href).status
end
