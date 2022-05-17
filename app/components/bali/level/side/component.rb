# frozen_string_literal: true

module Bali
  module Level
    module Side
      class Component < ApplicationViewComponent
        attr_reader :side, :options

        renders_many :items, Item::Component

        def initialize(side: :left, **options)
          @side = side
          @options = options
        end

        def classes
          "level-#{side} #{@class}"
        end

        def call
          tag.div class: classes, **options do
            items.size.positive? ? safe_join(items.map { |item| item }) : content
          end
        end
      end
    end
  end
end
