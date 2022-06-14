# frozen_string_literal: true

module Bali
  module Navbar
    module Burger
      class Component < ApplicationViewComponent
        attr_reader :type, :options

        def initialize(type: :main, **options)
          @type = type
          @options = prepend_class_name(options, 'navbar-burger burger')

          configure_attrs unless type.nil?
        end

        def call
          return tag.a(role: 'button', **options) { content } if content.present?

          tag.a role: 'button', **options do
            safe_join([
                        tag.span('aria-hidden': true),
                        tag.span('aria-hidden': true),
                        tag.span('aria-hidden': true)
                      ])
          end
        end

        private

        def configure_attrs
          attrs = type == :main ? attrs_for_main : attrs_for_alt

          prepend_action(options, attrs[:action])
          prepend_data_attribute(options, 'navbar-target', attrs[:target])
        end

        def attrs_for_main
          @attrs_for_main ||= { target: 'burger', action: 'navbar#toggleMenu' }
        end

        def attrs_for_alt
          @attrs_for_alt ||= { target: 'altBurger', action: 'navbar#toggleAltMenu' }
        end
      end
    end
  end
end
