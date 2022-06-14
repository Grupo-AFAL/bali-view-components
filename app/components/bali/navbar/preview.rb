# frozen_string_literal: true

module Bali
  module Navbar
    class Preview < ApplicationViewComponentPreview
      # Navbar
      # ---------------
      # The navbar component is a responsive and versatile horizontal navigation bar
      # @param fullscreen toggle
      # @param transparency toggle
      def default(fullscreen: false, transparency: false)
        render_with_template(
          template: 'bali/navbar/previews/default',
          locals: { fullscreen: fullscreen, transparency: transparency }
        )
      end

      # @param fullscreen toggle
      # @param transparency toggle
      def with_multiple_menus(fullscreen: false, transparency: false)
        render_with_template(
          template: 'bali/navbar/previews/with_multiple_menus',
          locals: { fullscreen: fullscreen, transparency: transparency }
        )
      end
    end
  end
end
