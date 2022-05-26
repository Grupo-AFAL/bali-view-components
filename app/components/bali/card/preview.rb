# frozen_string_literal: true

module Bali
  module Card
    class Preview < ApplicationViewComponentPreview

      def default
        render Card::Component.new(title: 'Title', description: 'Description', image: 'https://via.placeholder.com/320x244.png', link: '#') do |c|
          c.media do
            tag.div 'Media'
          end
          c.footer_item do
            tag.a 'Footer item with link', href: '#'
          end
        end
      end
    end
  end
end
