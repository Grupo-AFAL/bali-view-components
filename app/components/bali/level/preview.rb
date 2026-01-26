# frozen_string_literal: true

module Bali
  module Level
    class Preview < ApplicationViewComponentPreview
      # @param align select [start, center, end]
      def default(align: :center)
        render Bali::Level::Component.new(align: align.to_sym) do |c|
          c.with_left do |l|
            l.with_item(text: 'Left Item 1')
            l.with_item(text: 'Left Item 2')
          end

          c.with_right do |r|
            r.with_item(text: 'Right Item 1')
            r.with_item(text: 'Right Item 2')
          end
        end
      end

      # Use `items` directly when you don't need left/right positioning.
      # Items are rendered inline after any left/right content.
      def with_items_only
        render Bali::Level::Component.new do |c|
          c.with_item { tag.p('Item 1', class: 'font-medium') }
          c.with_item { tag.p('Item 2', class: 'font-medium') }
          c.with_item { tag.p('Item 3', class: 'font-medium') }
        end
      end
    end
  end
end
