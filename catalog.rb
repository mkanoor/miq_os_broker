require_relative 'service_template_to_osb'
require 'byebug'

class Catalog
  def initialize(options = {})
    @url           = options[:url]
    @user          = options[:user]
    @password      = options[:password]
    @verify_ssl    = options[:verify_ssl]
    raise "url not specified" unless @url
  end

  def get_catalog
    {'services' => get_template_hrefs['resources'].collect { |item| process_template_entry(item['href']) }}
  end

  def get_template_hrefs
    puts "Fetching Service Templates"
    rest_return = RestClient::Request.execute(:method     => :get,
                                              :url        => templates_url,
                                              :user       => @user,
                                              :password   => @password,
                                              :headers    => {:accept => :json},
                                              :verify_ssl => @verify_ssl)
    JSON.parse(rest_return) do |svc_templates|
      raise "Service Template #{templates_url} not found" unless svc_templates
    end 
  end

  def process_template_entry(href)
    options = { :user          => @user,
                :password      => @password,
                :verify_ssl    => @verify_ssl,
                :template_href => href }
    ServiceTemplateToOSB.new(options).convert
  end

  def templates_url
    parts = URI.parse(@url)
    parts.path = "/api/service_templates"
    parts.to_s
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  options[:user] = "admin"
  options[:password] = "xxxxxx"
  options[:verify_ssl] = false
  options[:url] = 'https://cfmeserver/api'
  puts Catalog.new(options).get_catalog.to_json
end
