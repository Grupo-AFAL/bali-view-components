# frozen_string_literal: true

module Bali
  module Navbar
    module Menu
      class Component < ApplicationViewComponent
        attr_reader :type, :options

        renders_many :start_items, Item::Component
        renders_many :end_items, Item::Component

        def initialize(type: :main, **options)
          @type = type
          @options = prepend_class_name(options, 'navbar-menu')

          set_target_attribute unless type.nil?
        end

        private

        def set_target_attribute
          target = type == :main ? 'menu' : 'altMenu'

          prepend_data_attribute(options, 'navbar-target', target)
        end
      end
    end
  end
end
