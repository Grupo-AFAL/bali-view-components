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
          tag.h1('Drawer content', class: 'title is-1')
        end
      end
    end
  end
end
