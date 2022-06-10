# frozen_string_literal: true

module Bali
  module Navbar
    module Burger
      class Component < ApplicationViewComponent
        attr_reader :options

        def initialize(**options)
          @options = prepend_class_name(options, 'navbar-burger burger')
          @options = prepend_data_attribute(options, 'navbar-target', 'burger')
        end

        def call
          tag.a role: 'button', **options do
            safe_join([
                        tag.span('aria-hidden': true),
                        tag.span('aria-hidden': true),
                        tag.span('aria-hidden': true)
                      ])
          end
        end
      end
    end
  end
end
