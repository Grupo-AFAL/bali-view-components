# frozen_string_literal: true

module Bali
  module Card
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Card
      # ---------------
      # Basic card view with image, title, description and footer.
      # @param style [Symbol] select [default, bordered, dash]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param shadow toggle
      def default(style: :default, size: :md, shadow: true)
        render Card::Component.new(style: style, size: size, shadow: shadow, class: 'w-96') do |c|
          c.with_image(
            src: 'https://img.daisyui.com/images/stock/photo-1606107557195-0e29a4b5b4aa.webp',
            href: '/'
          )

          c.with_footer_item(href: '#', class: 'btn-primary') do
            'Buy Now'
          end

          tag.div do
            safe_join([
                        tag.h2('Card Title', class: 'card-title'),
                        tag.p('A card component has a figure, a body part, and inside body there are title and actions parts.')
                      ])
          end
        end
      end

      # Card with Header
      def with_header
        render Card::Component.new(class: 'w-96') do |c|
          c.with_header(title: 'Header title')

          tag.p('Card content with header above')
        end
      end

      # @!endgroup

      # @!group Styles

      # Bordered Card
      # ---------------
      # Card with border style
      def bordered
        render Card::Component.new(style: :bordered, shadow: false, class: 'w-96') do |_c|
          tag.div do
            safe_join([
                        tag.h2('Bordered Card', class: 'card-title'),
                        tag.p('This card has a border style instead of shadow.')
                      ])
          end
        end
      end

      # Dash Card
      # ---------------
      # Card with dashed border
      def dash
        render Card::Component.new(style: :dash, shadow: false, class: 'w-96') do |_c|
          tag.div do
            safe_join([
                        tag.h2('Dash Card', class: 'card-title'),
                        tag.p('This card has a dashed border style.')
                      ])
          end
        end
      end

      # Side Layout
      # ---------------
      # Card with side image layout
      def side_layout
        render Card::Component.new(side: true, class: 'max-w-xl') do |c|
          c.with_image(src: 'https://img.daisyui.com/images/stock/photo-1635805737707-575885ab0820.webp')

          c.with_footer_item(href: '#', class: 'btn-primary') do
            'Watch'
          end

          tag.div do
            safe_join([
                        tag.h2('New movie is released!', class: 'card-title'),
                        tag.p('Click the button to watch on Jetflix app.')
                      ])
          end
        end
      end

      # Image Full
      # ---------------
      # Card with full background image
      def image_full
        render Card::Component.new(image_full: true, class: 'w-96') do |c|
          c.with_image(src: 'https://img.daisyui.com/images/stock/photo-1606107557195-0e29a4b5b4aa.webp')

          c.with_footer_item(href: '#', class: 'btn-primary') do
            'Buy Now'
          end

          tag.div do
            safe_join([
                        tag.h2('Full Image Card', class: 'card-title'),
                        tag.p('The image covers the entire card background.')
                      ])
          end
        end
      end

      # @!endgroup

      # @!group Custom

      # Custom Image
      # ---------------
      # Card view with custom image module, in this example we use the image with hover effect.
      def custom_image
        render_with_template(template: 'bali/card/previews/custom_image')
      end

      # @!endgroup
    end
  end
end
