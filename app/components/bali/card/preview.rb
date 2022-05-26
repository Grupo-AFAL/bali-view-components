# frozen_string_literal: true

module Bali
  module Card
    class Preview < ApplicationViewComponentPreview
      def default
        render Card::Component.new do |c|
          c.image(
            src: 'https://via.placeholder.com/320x244.png',
            href: '/'
          )

          c.footer_item(href: '#') do
            'Footer item with link'
          end

          c.footer_item do
            tag.span('Item with span')
          end

          tag.div('Title', class: 'title is-4')
        end
      end
    end
  end
end
