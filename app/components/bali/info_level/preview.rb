# frozen_string_literal: true

module Bali
  module InfoLevel
    class Preview < ApplicationViewComponentPreview
      # @param align select { choices: [start, center, end, between] }
      def default(align: :center)
        render InfoLevel::Component.new(align: align.to_sym) do |c|
          c.with_item do |i|
            i.with_heading('Posts')
            i.with_title('128')
          end

          c.with_item do |i|
            i.with_heading('Following')
            i.with_title('2,456')
          end

          c.with_item do |i|
            i.with_heading('Followers')
            i.with_title('12.3K')
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
