module Bali
  module ImageField
    class Preview < ApplicationViewComponentPreview
      # Default
      # ----------------
      # This will render the basic Image component
      def default
        render(Bali::ImageField::Component.new)
      end

      # Image with a custom image_url
      # ----------------
      # This will render the image component with an image loaded already
      # @param image_url text
      def with_image(image_url: 'avatar.png')
        render(Bali::ImageField::Component.new(image_url))
      end

      # Image with an input
      # ----------------
      # This will render the image component with an input to change the image
      def with_input
        render_with_template(template: 'bali/image_field/previews/with_input')
      end

      # Image with a custom clear button
      # ----------------
      # This will render the image component with an input to change the image and
      # a custom clear button
      def with_custom_clear_button
        render_with_template(template: 'bali/image_field/previews/with_custom_clear_button')
      end
    end
  end
end
