# frozen_string_literal: true

module Bali
  module Dropdown
    module Trigger
      class Component < ApplicationViewComponent
        def initialize(**options)
          @options = options
          @options[:tabindex] ||= 0
          @options[:role] ||= 'button'
          @options[:'aria-haspopup'] ||= 'true'
          @options[:'aria-expanded'] ||= 'false'
          @options[:data] ||= {}
          @options[:data][:dropdown_target] = 'trigger'
        end

        def call
          tag.div(**prepend_class_name(@options, 'btn')) do
            content
          end
        end
      end
    end
  end
end
