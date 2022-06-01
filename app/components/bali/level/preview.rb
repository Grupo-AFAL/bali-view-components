module Bali
  module Level
    class Preview < ApplicationViewComponentPreview
      def default
        render Bali::Level::Component.new do |c|
          c.level_left { tag.p 'Left' }
          c.level_right { tag.p 'Right' }          
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