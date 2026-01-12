# frozen_string_literal: true

module Bali
  module Navbar
    module Burger
      class Component < ApplicationViewComponent
        attr_reader :type, :options

        def initialize(type: :main, **options)
          @type = type
          @options = prepend_class_name(options, 'btn btn-ghost lg:hidden')

          configure_attrs unless type.nil?
        end

        def call
          return tag.button(role: 'button', **options) { content } if content.present?

          tag.button role: 'button', **options do
            tag.svg(
              xmlns: 'http://www.w3.org/2000/svg',
              class: 'h-5 w-5',
              fill: 'none',
              viewBox: '0 0 24 24',
              stroke: 'currentColor'
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

        private

        def configure_attrs
          attrs = type == :main ? attrs_for_main : attrs_for_alt

          prepend_action(options, attrs[:action])
          prepend_data_attribute(options, 'navbar-target', attrs[:target])
        end

        def attrs_for_main
          { target: 'burger', action: 'navbar#toggleMenu' }
        end

        def attrs_for_alt
          { target: 'altBurger', action: 'navbar#toggleAltMenu' }
        end
      end
    end
  end
end
