# frozen_string_literal: true

module Bali
  module Card
    module Image
      class Component < ApplicationViewComponent
        def initialize(src:, href: nil, alt: nil, figure_class: nil, **options)
          @src = src
          @href = href
          @alt = alt
          @figure_class = figure_class
          @options = options
        end

        def call
          tag.figure(class: @figure_class) do
            if @href.present?
              link_to @href do
                render_image
              end
            else
              render_image
            end
          end
        end

        private

        def render_image
          image_tag @src, **image_attributes
        end

        def image_attributes
          @options.merge(
            alt: @alt,
            class: class_names('w-full', @options[:class])
          )
        end
      end
    end
  end
end
