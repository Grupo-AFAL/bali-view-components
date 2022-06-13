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
      # @param split_menu_on_mobile toggle
      def split_menu_on_mobile(fullscreen: false, transparency: false, split_menu_on_mobile: true)
        render_with_template(
          template: 'bali/navbar/previews/split_menu_on_mobile',
          locals: { 
            fullscreen: fullscreen, 
            transparency: transparency,
            split_menu_on_mobile: split_menu_on_mobile
          }
        )
      end
    end
  end
end
