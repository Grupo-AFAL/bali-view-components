# frozen_string_literal: true

require 'bali/version'
require 'bali/engine'
require 'bali/filter_form'
require 'bali/form_builder/html_utils'
require 'bali/form_builder/shared_utils'
require 'bali/form_builder/shared_date_utils'
require 'bali/layout_concern'
require 'bali/types/time_value'
require 'bali/types/month_value'
require 'bali/utils'
require 'bali/html_element_helper'
require 'bali/path_helper'
require 'bali/form_helper'
require 'bali/auto_submit_select_helper'

Dir[File.join(File.dirname(__FILE__), 'bali/concerns', '**/*.rb')].each do |concern|
  require concern
end

builder_helpers = File.join(File.dirname(__FILE__), 'bali/form_builder', '*_fields.rb')

Dir.glob(builder_helpers).each do |builder_helper|
  require builder_helper
end

require 'bali/form_builder'

module Bali
  mattr_accessor :native_app, default: false
  mattr_accessor :custom_icons, default: {}
  mattr_accessor :ios_user_agent, default: /Turbo Native \(iOS\)/
  mattr_accessor :android_user_agent, default: /Turbo Native \(Android\)/

  def self.add_icon(name, svg_str)
    custom_icons[name.to_s] = svg_str
  end

  def self.config
    yield(self)
  end
end
