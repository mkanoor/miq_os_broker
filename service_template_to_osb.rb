##!/usr/env ruby
#

require_relative 'service_template_parameters'
require_relative 'service_template'

class ServiceTemplateToOSB
  PROVISION_TASK_NAME = "CloudForms Provisioning Task"
  DEFAULT_PLAN_NAME   = "default"
  DEFAULT_PLAN_ID     = "default"

  def initialize(options = {})
    @svc_template  = ServiceTemplate.new(options)
  end

  def osb_normalize_name(name)
    @osb_name ||= "#{name.downcase.gsub(/[()_,. ]/, '-')}-apb"
  end

  def convert
    puts "Converting to OSB API SPEC for service template #{@svc_template.object['name']}"
    metadata = { 'displayName' => "#{@svc_template.object['name']} (APB)" }
    metadata['imageUrl'] = @svc_template.object['picture']['image_href'] if @svc_template.object['picture']

    @svc_template.object['description'] = 'No description provided' if @svc_template.object['description'].empty?

  # {'version'     => 1.0,
  {
   'name'        => osb_normalize_name(@svc_template.object['name']),
   'id'          => @svc_template.object['guid'],
   'description' => @svc_template.object['description'] || 'No description provided',
   'bindable'    => false,
   'async'       => 'optional',
   'metadata'    => metadata,
   'plans'       => [default_plan(svc_parameters)]
  }
  end


  def default_plan(parameters)
    {
     'name'        => DEFAULT_PLAN_NAME,
     'description' => "Default deployment plan for #{@svc_template.object['name']}-apb",
     'free'        => true,
     'id'          => @svc_template.object['guid'],
     'metadata'    => plan_metadata,
     'schemas'     => schemas(parameters)
    }
  end

  def schemas(parameters)
    { 'service_instance' => 
      {
        'create' => { 'parameters' => parameters }
      }
    }
  end

  def plan_metadata
    { 'displayName' => 'Default',
      'longDescription' => "This plan deploys an instance of #{@svc_template.object['name']}",
      'cost'            => '$0.0'
    }
  end

  def svc_parameters(action = 'provision')
    action_parameters = ServiceTemplateParameters.new
    result = @svc_template.get_dialog(action)
    action_parameters.process_tabs(result['content'][0]['dialog_tabs']) if result['content']
    service_catalog_href = @svc_template.api_url+"/service_catalogs/" +  @svc_template.object['service_template_catalog_id'] + "/service_templates"
    action_parameters.add_readonly_property('service_catalog_href', 'string', service_catalog_href)
    action_parameters.add_readonly_property('href', 'string', @svc_template.object['href'])
    action_parameters.parameters
  rescue => err
    puts "#{err}"
    puts "#{err.backtrace}"
    exit!
  end
end
