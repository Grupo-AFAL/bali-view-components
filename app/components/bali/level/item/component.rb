# frozen_string_literal: true

module Bali
  module Level
    module Item
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'level-item flex items-center max-w-full'

        def initialize(text: nil, **options)
          @text = text
          @options = options
        end

        def call
          tag.div(class: item_classes, **options.except(:class)) do
            @text || content
          end
        end

        private

        attr_reader :options

        def item_classes
          class_names(BASE_CLASSES, options[:class])
        end
      end
    end
  end
end
