# frozen_string_literal: true

module Bali
  module InfoLevel
    class Preview < ApplicationViewComponentPreview
      def default
        render InfoLevel::Component.new do |c|
          c.item do |i|
            i.heading('Heading 1')
            i.title('Title 1')
          end

          c.item do |i|
            i.heading('Heading 2')
            i.title('Title 2')
          end
        end
      end
    end
  end
end
