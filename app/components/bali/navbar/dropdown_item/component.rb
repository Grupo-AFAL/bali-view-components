# frozen_string_literal: true

module Bali
  module Navbar
    module DropdownItem
      class Component < ApplicationViewComponent
        WRAPPER_CLASSES = 'dropdown dropdown-hover'
        TRIGGER_CLASSES = 'flex items-center gap-1'
        MENU_CLASSES = 'menu bg-base-100 rounded-box z-50 w-52 p-2 shadow-lg'

        # Simple struct for dropdown menu items
        Item = Struct.new(:name, :href, :options, keyword_init: true)

        # @param name [String] Dropdown trigger text
        # @param icon [String] Icon name for dropdown indicator (default: chevron-down)
        def initialize(name:, icon: 'chevron-down', **options)
          @name = name
          @icon = icon
          @options = options
          @items = []
        end

        attr_reader :name, :icon, :items

        # Add an item to the dropdown menu
        def with_item(name:, href: '#', **options)
          @items << Item.new(name: name, href: href, options: options)
        end

        def wrapper_classes
          class_names(WRAPPER_CLASSES, @options[:class])
        end

        def trigger_classes
          TRIGGER_CLASSES
        end

        def menu_classes
          MENU_CLASSES
        end
      end
    end
  end
end
