# frozen_string_literal: true

module Bali
  module Modal
    module Actions
      class Component < ApplicationViewComponent
        def initialize(**options)
          @options = options
        end

        def call
          tag.div(class: actions_classes, **@options.except(:class)) do
            content
          end
        end

        private

        def actions_classes
          class_names(
            'modal-action flex justify-end gap-2 pt-4',
            @options[:class]
          )
        end
      end
    end
  end
end
