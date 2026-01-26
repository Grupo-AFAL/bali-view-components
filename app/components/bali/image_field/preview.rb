# frozen_string_literal: true

module Bali
  module ImageField
    class Preview < ApplicationViewComponentPreview
      # @param size select { choices: [xs, sm, md, lg, xl] }
      def default(size: :md)
        render(Bali::ImageField::Component.new(size: size.to_sym))
      end

      # With a custom image
      # Use `src:` to provide an existing image URL.
      # @param size select { choices: [xs, sm, md, lg, xl] }
      def with_image(size: :md)
        render(Bali::ImageField::Component.new(
                 src: 'avatar.png',
                 size: size.to_sym
               ))
      end

      # With file input
      # Add the `input` slot to enable image uploads.
      # The component shows a hover overlay with camera icon and a clear button.
      def with_input
        render_with_template(template: 'bali/image_field/previews/with_input')
      end

      # With custom clear button
      # Override the default clear button using the `clear_button` slot.
      def with_custom_clear_button
        render_with_template(template: 'bali/image_field/previews/with_custom_clear_button')
      end
    end
  end
end
