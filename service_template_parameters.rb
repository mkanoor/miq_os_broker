##!/usr/env ruby
#

class ServiceTemplateParameters
  attr_reader :enum_mappings
  attr_reader :parameters
  def initialize()
    @enum_mappings  = {}
    @properties     = {}
    @parameters     = {}
    @parameters['$schema'] = "http://json-schema.org/draft-04/schema#"
    @parameters['type']    = 'object'
    @parameters['required'] = []
    @parameters['properties'] = @properties
  end

  def process_tabs(tabs)
    tabs.each { |tab| process_tab(tab) }
  end

  def add_readonly_property(name, type, value)
    @properties[name] = { 'readonly' => true, 'type'=> type, 'default' => value}
  end

  private
  def process_tab(tab)
    tab['dialog_groups'].each do |section|
      process_section(tab['label'],section)
    end
  end


  def process_section(tab_label, section)
    display_group = "#{tab_label}/#{section['label']}"
    section['dialog_fields'].each do |dialog_field|
      raise "Dynamic fields are not currently supported" if dialog_field['dynamic']
      name = dialog_field['name']
      item = initialize_osb_property(dialog_field, display_group, name)
      send(dialog_field['type'].to_sym, dialog_field, item)
      @properties[name] = item
    end
  end

  def initialize_osb_property(dialog_field, display_group, name)
    item = {}
    item['description'] = dialog_field['label']
    item['default'] = convert_datatype(dialog_field['data_type'], dialog_field['default_value']) unless dialog_field['default_value'].empty?
    # item['default'] = dialog_field['default_value'] unless dialog_field['default_value'].empty?
    item['display_group'] = display_group
    item['pattern'] = dialog_field['validator_rule'] if dialog_field['validator_rule']
    # type: enum|string|boolean|int|number|bool
    item['type'] = set_datatype(dialog_field['data_type'])
    add_to_required(name) if dialog_field['required']
    item
  end

  def add_to_required(name)
    @parameters['required'] << name
  end

  def DialogFieldTextBox(dialog_field, item)
    # display_type: password|textarea|text
    if dialog_field['options']['protected']
      item['display_type'] = 'password'
    end
    # max_length
    # updatable : True/False for enum's where a user can enter a value
  end

  def DialogFieldTextAreaBox(dialog_field, item)
    DialogFieldTextBox(dialog_field, item)
    item['display_type'] = 'textarea'
  end

  def DialogFieldCheckBox(dialog_field, item)
    item['type'] = 'boolean'
    if dialog_field['default_value'] == 't'
      item['default'] = true
    else
      item['default'] = false
    end
  end

  def DialogFieldRadioButton(dialog_field, item)
    item['type'] = 'enum'
    item['enum'] = dialog_field['values'].flat_map { |x| x[1] }
    @enum_mappings[item['name']] = dialog_field['values'].each_with_object({}) { |x, hash| hash[x[1]] = x[0] }

  end

  def DialogFieldDateControl(dialog_field, item)
  end

  def DialogFieldDateTimeControl(dialog_field, item)
  end

  def DialogFieldDropDownList(dialog_field, item)
    item['type'] = 'enum'
    item['enum'] = dialog_field['values'].flat_map { |x| x[1] }
    @enum_mappings[item['name']] = dialog_field['values'].each_with_object({}) { |x, hash| hash[x[1]] = x[0] }
    
  end

  def DialogFieldTagControl(dialog_field, item)
    item['type'] = 'enum'
    item['enum'] = dialog_field['values'].flat_map { |x| x['name'] }
    @enum_mappings[item['name']] = dialog_field['values'].each_with_object({}) { |x, hash| hash[x['name']] = x['id'] }
  end

  def set_datatype(cfme_type)
    case cfme_type
    when "string"
      "string"
    when "integer"
      "integer"
    else
      "string"
    end
  end

  def convert_datatype(cfme_type, cfme_value)
    case cfme_type
    when "string"
      cfme_value
    when "integer"
      cfme_value.to_i
    else
      cfme_value
    end
  end
end
