# frozen_string_literal: true

module Bali
  module Navbar
    class Preview < ApplicationViewComponentPreview
      # @param fullscreen toggle
      # @param transparency toggle
      # @param color [Symbol] select [base, primary, secondary, accent, neutral]
      def default(fullscreen: false, transparency: false, color: :base)
        render_with_template(
          template: 'bali/navbar/previews/default',
          locals: { fullscreen: fullscreen, transparency: transparency, color: color }
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
