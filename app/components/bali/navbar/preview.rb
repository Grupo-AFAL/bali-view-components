# frozen_string_literal: true

module Bali
  module Navbar
    class Preview < ApplicationViewComponentPreview
      # @param fullscreen toggle "Edge-to-edge layout vs centered (1152px max)"
      # @param transparency toggle
      # @param color [Symbol] select [base, primary, secondary, accent, neutral]
      # **Fullscreen**: removes the max-width constraint so content spans edge-to-edge.
      # **Non-fullscreen** (default): content centered with 1152px max-width.
      def default(fullscreen: false, transparency: false, color: :base)
        render_with_template(
          template: 'bali/navbar/previews/default',
          locals: { fullscreen: fullscreen, transparency: transparency, color: color }
        )
      end

      # @param fullscreen toggle "Edge-to-edge layout vs centered (1152px max)"
      # @param transparency toggle
      # @param color [Symbol] select [base, primary, secondary, accent, neutral]
      def with_multiple_menus(fullscreen: false, transparency: false, color: :base)
        render_with_template(
          template: 'bali/navbar/previews/with_multiple_menus',
          locals: { fullscreen: fullscreen, transparency: transparency, color: color }
        )
      end
    end
  end
end
