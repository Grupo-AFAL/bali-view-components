# frozen_string_literal: true

require 'bali/version'
require 'bali/engine'
require 'bali/filter_form'

module Bali
  class Engine < ::Rails::Engine; end
  class Error < StandardError; end
end
