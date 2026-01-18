# frozen_string_literal: true

module Bali
  module Navbar
    module Burger
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'btn btn-ghost lg:hidden'
        ICON_CLASSES = 'h-5 w-5'

        CONFIGURATIONS = {
          main: { target: 'burger', action: 'navbar#toggleMenu' },
          alt: { target: 'altBurger', action: 'navbar#toggleAltMenu' }
        }.freeze

        def initialize(type: :main, **options)
          @type = type
          @options = prepend_class_name(options, BASE_CLASSES)

          configure_attrs unless type.nil?
        end

        def call
          tag.button(role: 'button', 'aria-label': t('.toggle_menu'), **@options) do
            content.presence || default_icon
          end
        end

        private

        attr_reader :type, :options

        def configure_attrs
          attrs = CONFIGURATIONS.fetch(@type, CONFIGURATIONS[:main])

          prepend_action(@options, attrs[:action])
          prepend_data_attribute(@options, 'navbar-target', attrs[:target])
        end

        def default_icon
          tag.svg(
            xmlns: 'http://www.w3.org/2000/svg',
            class: ICON_CLASSES,
            fill: 'none',
            viewBox: '0 0 24 24',
            stroke: 'currentColor',
            'aria-hidden': 'true'
          ) do
            tag.path(
              'stroke-linecap': 'round',
              'stroke-linejoin': 'round',
              'stroke-width': '2',
              d: 'M4 6h16M4 12h8m-8 6h16'
            )
          end
        end
      end
    end
  end
end
