# frozen_string_literal: true

module Bali
  module Navbar
    module Menu
      class Component < ApplicationViewComponent
        # Desktop: horizontal menu inline with navbar
        # Mobile: vertical menu dropdown below navbar
        MENU_CLASSES_MOBILE = 'menu flex-col gap-1'
        MENU_CLASSES_DESKTOP = 'lg:menu-horizontal lg:flex-row lg:gap-0'

        TARGETS = {
          main: 'menu',
          alt: 'altMenu'
        }.freeze

        # Mobile: absolute positioned below navbar, full width, hidden by default
        # Desktop: inline with navbar, fills remaining space
        WRAPPER_CLASSES_MOBILE = %w[
          hidden flex-col gap-4 absolute left-0 top-full
          w-full bg-base-100 shadow-lg p-4 z-40
        ].join(' ').freeze

        WRAPPER_CLASSES_DESKTOP = %w[
          lg:flex lg:flex-1 lg:static lg:flex-row lg:items-center
          lg:gap-4 lg:bg-transparent lg:shadow-none lg:p-0 lg:z-auto
        ].join(' ').freeze

        renders_many :start_items, Item::Component
        renders_many :end_items, Item::Component

        def initialize(type: :main, **options)
          @type = type
          @options = options
        end

        def menu_classes
          class_names(MENU_CLASSES_MOBILE, MENU_CLASSES_DESKTOP)
        end

        # Options hash for the outer wrapper that gets toggled
        def menu_wrapper_options
          opts = { class: wrapper_classes }
          apply_target_attribute(opts) unless @type.nil?
          opts
        end

        # Classes for start_items inner div
        def start_items_classes
          'flex flex-col lg:flex-row lg:items-center'
        end

        # Classes for end_items inner div (ml-auto pushes to right on desktop)
        def end_items_classes
          'flex flex-col lg:flex-row lg:items-center gap-2 lg:ml-auto'
        end

        def wrapper_classes
          class_names(WRAPPER_CLASSES_MOBILE, WRAPPER_CLASSES_DESKTOP)
        end

        private

        attr_reader :type

        def apply_target_attribute(opts)
          target = TARGETS.fetch(@type, TARGETS[:main])
          prepend_data_attribute(opts, 'navbar-target', target)
        end
      end
    end
  end
end
