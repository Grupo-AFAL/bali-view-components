# frozen_string_literal: true

module Bali
  module Navbar
    module Menu
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'navbar-center hidden lg:flex'
        MENU_CLASSES = 'menu menu-horizontal px-1'

        TARGETS = {
          main: 'menu',
          alt: 'altMenu'
        }.freeze

        renders_many :start_items, Item::Component
        renders_many :end_items, Item::Component

        def initialize(type: :main, **options)
          @type = type
          @options = prepend_class_name(options, BASE_CLASSES)

          set_target_attribute unless type.nil?
        end

        def menu_classes
          MENU_CLASSES
        end

        private

        attr_reader :type, :options

        def set_target_attribute
          target = TARGETS.fetch(@type, TARGETS[:main])
          prepend_data_attribute(@options, 'navbar-target', target)
        end
      end
    end
  end
end
