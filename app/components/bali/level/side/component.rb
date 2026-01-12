# frozen_string_literal: true

module Bali
  module Level
    module Side
      class Component < ApplicationViewComponent
        attr_reader :position, :options

        renders_many :items, Item::Component

        def initialize(position: :left, **options)
          @position = position
          @options = prepend_class_name(options, side_classes)
        end

        def call
          tag.div(**options) do
            items.size.positive? ? safe_join(items.map { |item| item }) : content
          end
        end

        private

        def side_classes
          class_names(
            "level-#{position}",
            'flex items-center gap-4'
          )
        end
      end
    end
  end
end
