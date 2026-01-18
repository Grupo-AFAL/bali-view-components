# frozen_string_literal: true

module Bali
  module ImageGrid
    class Preview < ApplicationViewComponentPreview
      PLACEHOLDER_URL = 'https://placehold.co/480x320'

      # @param columns select { choices: [2, 3, 4, 5, 6] }
      # @param gap select { choices: [none, sm, md, lg] }
      # @param aspect_ratio select { choices: [square, video, 3/2, 4/3, 4/5, 16/9] }
      # @param image_count number
      def default(columns: 4, gap: :md, aspect_ratio: :'3/2', image_count: 9)
        render(ImageGrid::Component.new(columns: columns.to_i, gap: gap.to_sym)) do |c|
          image_count.to_i.times do
            c.with_image(aspect_ratio: aspect_ratio.to_sym) { tag.img src: PLACEHOLDER_URL }
          end
        end
      end

      # With footer content on each image
      # ----------------------------------
      # Each image card can have a footer slot for captions or metadata.
      def with_footer
        render_with_template
      end
    end
  end
end
