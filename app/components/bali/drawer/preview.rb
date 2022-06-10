# frozen_string_literal: true

module Bali
  module Drawer
    class Preview < ApplicationViewComponentPreview
      # Drawer
      # ---------------
      # Renders any content inside a drawer.
      # @param active toggle
      def default(active: true)
        render Bali::Drawer::Component.new(active: active) do
          safe_join([
            tag.h1('Drawer Title', class: 'title is-1'),
            tag.p('Drawer content')
          ])
        end
      end
    end
  end
end
