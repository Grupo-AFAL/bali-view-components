# frozen_string_literal: true

module Bali
  module Navbar
    module Menu
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_many :start_items, Item::Component
        renders_many :end_items, Item::Component

        def initialize(**options)
          @options = prepend_class_name(options, 'navbar-menu')
        end
      end
    end
  end
end
