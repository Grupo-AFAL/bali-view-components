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

      def with_custom_heading
        render InfoLevel::Component.new do |c|
          c.item do |i|
            i.heading do
              tag.p('Custom') + tag.p('heading')
            end

            i.title('Title 1')
          end
        end
      end

      def with_custom_title
        render InfoLevel::Component.new do |c|
          c.item do |i|
            i.heading('Heading 1')

            i.title do
              tag.p('Custom') + tag.p('title')
            end
          end
        end
      end
    end
  end
end
