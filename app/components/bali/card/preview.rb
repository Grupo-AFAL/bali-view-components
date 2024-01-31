# frozen_string_literal: true

module Bali
  module Card
    class Preview < ApplicationViewComponentPreview
      # Card view
      # ---------------
      # Basic card view with image, title, description and footer.
      def default
        render Card::Component.new do |c|
          c.with_image(
            src: 'https://via.placeholder.com/320x244.png',
            href: '/'
          )

          c.with_footer_item(href: '#') do
            'Footer item with link'
          end

          c.with_footer_item do
            tag.span('Item with span')
          end

          tag.div('Title', class: 'title is-4')
        end
      end

      def with_header
        render Card::Component.new do |c|
          c.with_header(title: 'Header title')

          tag.p('Card content')
        end
      end

      # Card view
      # ---------------
      # Card view with custom image module, in this example we use the image with hover effect.
      def custom_image
        render_with_template(template: 'bali/card/previews/custom_image')
      end
    end
  end
end
