# frozen_string_literal: true

require 'bali/version'
require 'bali/engine'
require 'bali/filter_form'
require 'bali/form_builder/html_utils'
require 'bali/form_builder/shared_utils'
require 'bali/form_builder/shared_date_utils'
require 'bali/layout_concern'
require 'bali/types/time_value'
require 'bali/utils'
require 'bali/html_element_helper'
require 'bali/path_helper'

builder_helpers = File.join(File.dirname(__FILE__), 'bali/form_builder', '*_fields.rb')

Dir.glob(builder_helpers).each do |builder_helper|
  require builder_helper
end

require 'bali/form_builder'

module Bali
  # Your code goes here...
end
