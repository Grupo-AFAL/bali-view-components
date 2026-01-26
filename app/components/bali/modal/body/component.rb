# frozen_string_literal: true

module Bali
  module Modal
    module Body
      class Component < ApplicationViewComponent
        def initialize(modal_id: nil, **options)
          @modal_id = modal_id
          @options = options
        end

        def call
          tag.div(id: description_id, class: body_classes, **@options.except(:class)) do
            content
          end
        end

        private

        def body_classes
          class_names(
            'modal-body py-4',
            @options[:class]
          )
        end

        def description_id
          "#{@modal_id}-description" if @modal_id
        end
      end
    end
  end
end
