module Bali
  module Avatar
    class Preview < ApplicationViewComponentPreview
      def default
        # Default Avatar
        # ----------------
        # This will render the basic avatar component
        # @params placeholder_url text
        render_with_template(
          template: 'bali/avatar/previews/default',
          locals: {
            placeholder_url: 'bulma-default.png'
          }
        )
      end

      # Avatar with an image
      # ----------------
      # This will render the avatar component with an image loaded already
      # @param image_url text
      def with_image(image_url: 'avatar.png')
        render_with_template(
          template: 'bali/avatar/previews/with_image',
          locals: {
            image_url: image_url
          }
        )
      end
    end
  end
end
