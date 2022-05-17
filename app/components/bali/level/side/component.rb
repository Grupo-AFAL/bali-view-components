# frozen_string_literal: true

module Bali
  module Level
    module Side
      class Component < ApplicationViewComponent
        attr_reader :position, :options

        renders_many :items, Item::Component

        def initialize(position: :left, **options)
          @position = position
          @options = prepend_class_name(options, "level-#{position}")
        end

        def call
          tag.div **options do
            items.size.positive? ? safe_join(items.map { |item| item }) : content
          end
        end
      end
    end
  end
end
