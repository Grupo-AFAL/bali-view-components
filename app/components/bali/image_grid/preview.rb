# frozen_string_literal: true

module Bali
  module ImageGrid
    class Preview < ApplicationViewComponentPreview
      URL_3_2 = 'https://placehold.co/480x320'
      URL_4_5 = 'https://placehold.co/480x600'

      # Default Image Grid
      # ------------------
      # Render 4 images per row and 3/2 image ratio
      def default
        render(ImageGrid::Component.new) do |c|
          9.times do
            c.with_image { tag.img src: URL_3_2 }
          end
        end
      end

      # Custom image ratio
      # ------------------
      # Change the class on the figure element
      def image_ratio
        render(ImageGrid::Component.new) do |c|
          9.times do
            c.with_image(image_ratio: 'is-4by5') { tag.img src: URL_4_5 }
          end
        end
      end

      # Custom number of columns
      # ---------------
      # Change the class on the div.column element
      def column_size
        render(ImageGrid::Component.new) do |c|
          9.times do
            c.with_image(column_size: 'is-one-fifth') { tag.img src: URL_3_2 }
          end
        end
      end
    end
  end
end
