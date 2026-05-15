# frozen_string_literal: true

module Bali
  module ImageGrid
    class Preview < ApplicationViewComponentPreview
      PLACEHOLDER_URL = 'https://placehold.co/480x320'

      # @param columns select { choices: [2, 3, 4, 5, 6] }
      # @param gap select { choices: [none, sm, md, lg] }
      # @param aspect_ratio select { choices: [square, video, 3/2, 4/3, 4/5, 16/9] }
      # @param image_count number
      # @param expandable toggle
      def default(columns: 4, gap: :md, aspect_ratio: :'3/2', image_count: 9, expandable: false)
        render(ImageGrid::Component.new(columns: columns.to_i, gap: gap.to_sym, expandable: expandable)) do |c|
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

      # Expandable images
      # -----------------
      # Click any image to open it in a fullscreen lightbox. Pass `full_src:`
      # to load a higher-resolution image in the lightbox; otherwise the
      # thumbnail's `src` is reused.
      #
      # ```erb
      # <%= render Bali::ImageGrid::Component.new(expandable: true) do |c| %>
      #   <% c.with_image(full_src: '/path/to/full.jpg') do %>
      #     <%= image_tag '/path/to/thumb.jpg' %>
      #   <% end %>
      # <% end %>
      # ```
      def expandable
        render(ImageGrid::Component.new(columns: 3, gap: :md, expandable: true)) do |c|
          6.times do |i|
            c.with_image(
              aspect_ratio: :'3/2',
              full_src: "https://placehold.co/1600x1067?text=Full+#{i + 1}"
            ) do
              tag.img(src: "https://placehold.co/480x320?text=Image+#{i + 1}",
                      alt: "Sample image #{i + 1}")
            end
          end
        end
      end
    end
  end
end
