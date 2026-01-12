# frozen_string_literal: true

module Bali
  module Drawer
    class Preview < ApplicationViewComponentPreview
      # Default Drawer
      # ---------------
      # Renders any content inside a drawer panel
      # @param active toggle
      # @param size [Symbol] select [narrow, medium, wide, extra_wide]
      def default(active: true, size: :medium)
        render Bali::Drawer::Component.new(active: active, size: size) do
          safe_join([
                      tag.h1('Drawer Title', class: 'text-2xl font-bold mb-4'),
                      tag.p('This is the drawer content. It slides in from the right side of the screen.')
                    ])
        end
      end
    end
  end
end
