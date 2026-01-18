# frozen_string_literal: true

module Bali
  module Level
    module Side
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'flex items-center gap-4 shrink'

        renders_many :items, Item::Component

        def initialize(position: :left, **options)
          @position = position
          @options = options
        end

        def call
          tag.div(class: side_classes, **options.except(:class)) do
            items.any? ? safe_join(items) : content
          end
        end

        private

        attr_reader :position, :options

        def side_classes
          class_names(
            "level-#{position}",
            BASE_CLASSES,
            options[:class]
          )
        end
      end
    end
  end
end
