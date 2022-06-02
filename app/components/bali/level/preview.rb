# frozen_string_literal: true

module Bali
  module Level
    class Preview < ApplicationViewComponentPreview
      def default
        render Bali::Level::Component.new do |c|
          c.left do |l|
            l.item(text: 'Item 1')
            l.item(text: 'Item 2')
            l.item(text: 'Item 3')
          end

          c.right do |r|
            r.item(text: 'Item 1')
            r.item(text: 'Item 2')
          end
        end
      end

      def only_with_level_items
        render Bali::Level::Component.new do |c|
          c.item { tag.p 'Item 1' }
          c.item { tag.p 'Item 2' }
          c.item { tag.p 'Item 3' }
        end
      end
    end
  end
end
