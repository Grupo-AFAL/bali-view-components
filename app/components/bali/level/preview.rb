# frozen_string_literal: true

module Bali
  module Level
    class Preview < ApplicationViewComponentPreview
      # @param align select [top, center, bottom]
      def default(align: :center)
        render Bali::Level::Component.new(align: align) do |c|
          c.with_left do |l|
            l.item(text: 'Item 1')
            l.item(text: 'Item 2')
            l.item(text: 'Item 3')
          end

          c.with_right do |r|
            r.item(text: 'Item 1')
            r.item(text: 'Item 2')
          end
        end
      end

      def only_with_level_items
        render Bali::Level::Component.new do |c|
          c.with_item { tag.p 'Item 1' }
          c.with_item { tag.p 'Item 2' }
          c.with_item { tag.p 'Item 3' }
        end
      end
    end
  end
end
