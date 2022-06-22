# frozen_string_literal: true

require 'bali/version'
require 'bali/engine'
require 'bali/filter_form'
require 'bali/types/time_value'

module Bali
  # Your code goes here...
end

ActiveSupport.on_load :active_record do
  include Bali::Types
end
