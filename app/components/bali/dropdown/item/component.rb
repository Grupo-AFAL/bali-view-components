# frozen_string_literal: true

module Bali
  module Dropdown
    module Item
      class Component < ApplicationViewComponent
        def initialize(**options)
          @options = options
        end

        def call
          tag.a(**prepend_class_name(@options, 'dropdown-item')) do
            content
          end
        end
      end
    end
  end
end
