# frozen_string_literal: true

module Bali
  module Dropdown
    module Trigger
      class Component < ApplicationViewComponent
        def initialize(**options)
          @options = options
        end

        def call
          tag.a(**prepend_action(@options, 'dropdown#toggleMenu')) do
            content
          end
        end
      end
    end
  end
end
