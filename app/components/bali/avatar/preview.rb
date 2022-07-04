module Bali
  module Avatar
    class Preview < ApplicationViewComponentPreview
      def default
        render_with_template(
          template: 'bali/avatar/previews/default'
        )
      end

      def with_image
        render_with_template(
          template: 'bali/avatar/previews/with_image',
          locals: {
            image_url: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR8qsnp3N8vzUr0SdcfX8ILtjAipw3bNA9DAg&usqp=CAU'
          }
        )
      end
    end
  end
end
