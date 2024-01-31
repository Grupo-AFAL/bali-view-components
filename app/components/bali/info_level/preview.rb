# frozen_string_literal: true

module Bali
  module InfoLevel
    class Preview < ApplicationViewComponentPreview
      # @param align select [left, center, right]
      def default(align: 'center')
        render InfoLevel::Component.new(align: align) do |c|
          c.with_item do |i|
            i.with_heading('Heading 1')
            i.with_title('Title 1')
          end

          c.with_item do |i|
            i.with_heading('Heading 2')
            i.with_title('Title 2')
          end
        end
      end

      def with_custom_heading
        render InfoLevel::Component.new do |c|
          c.with_item do |i|
            i.with_heading do
              tag.p('Custom') + tag.p('heading')
            end

            i.with_title('Title 1')
          end
        end
      end

      def with_custom_title
        render InfoLevel::Component.new do |c|
          c.with_item do |i|
            i.with_heading('Heading 1')

            i.with_title do
              tag.p('Custom') + tag.p('title')
            end
          end
        end
      end
    end
  end
end
