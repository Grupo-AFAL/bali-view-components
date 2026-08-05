# frozen_string_literal: true

module Bali
  module Navbar
    class Preview < ApplicationViewComponentPreview
      # @param fullscreen toggle "Edge-to-edge layout vs centered (1152px max)"
      # @param transparency toggle
      # @param shadow toggle "Drop shadow under the bar"
      # @param color [Symbol] select [base, primary, secondary, accent, neutral]
      # **Fullscreen**: removes the max-width constraint so content spans edge-to-edge.
      # **Non-fullscreen** (default): content centered with 1152px max-width.
      #
      # **Shadow**: on by default. Turn it off in a layout where the bar already
      # separates itself — an app shell whose navbar carries a bottom border that
      # continues the sidebar's draws two dividers otherwise.
      def default(fullscreen: false, transparency: false, shadow: true, color: :base)
        render_with_template(
          template: 'bali/navbar/previews/default',
          locals: {
            fullscreen: fullscreen,
            transparency: transparency,
            shadow: shadow,
            color: color
          }
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

      # @label Sidebar burger + transparency
      # @param transparency toggle
      # The navbar whose hamburger opens the SideMenu instead of the navbar's own menu —
      # `nav.with_burger(type: :sidebar)`. It is the composition #811 broke, and the only one
      # the package had no preview for: `Burger::CONFIGURATIONS[:sidebar]` is empty, so this
      # navbar renders no `data-navbar-target="burger"`, and the transparency scroll handler
      # used to throw on every scroll event reading a target that is not there. Scroll past
      # the navbar's height: the background must come back.
      def with_sidebar_burger(transparency: true)
        render_with_template(
          template: 'bali/navbar/previews/with_sidebar_burger',
          locals: { transparency: transparency }
        )
      end
    end
  end
end
