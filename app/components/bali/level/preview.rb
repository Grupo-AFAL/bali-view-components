# frozen_string_literal: true

module Bali
  module Level
    class Preview < ApplicationViewComponentPreview
      def default
        render Level::Component.new do |c|
          c.left do |l|
            l.item(text: 'Item 1')
            l.item(text: 'Item 2')
          end

          c.right do |r|
            r.item(text: 'Item 1')
            r.item(text: 'Item 2')
          end
        end
      end
    end
  end
end
