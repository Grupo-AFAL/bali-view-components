module Bali
  module Avatar
    class Preview < ApplicationViewComponentPreview
      def default
        # Default Avatar
        # ----------------
        # This will render the basic avatar component
        render_with_template(
          template: 'bali/avatar/previews/default'
        )
      end

      # Avatar with an image
      # ----------------
      # This will render the avatar component with an image loaded already
      # @param image_url text
      def with_image(image_url: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR8qsnp3N8vzUr0SdcfX8ILtjAipw3bNA9DAg&usqp=CAU')
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
