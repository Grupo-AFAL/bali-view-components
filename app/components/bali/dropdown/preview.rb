# frozen_string_literal: true

module Bali
  module Dropdown
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Dropdown
      # ---------------
      # Dropdown with a list of items. Trigger supports multiple variants:
      # - `:button` (default) - Standard button
      # - `:icon` - Ghost button with circle (for icon-only triggers)
      # - `:ghost` - Ghost button (transparent background)
      # - `:custom` - No base classes (fully customizable)
      # @param hoverable toggle
      # @param close_on_click toggle
      # @param align [Symbol] select [left, right, top, bottom, top_end, bottom_end]
      # @param wide toggle
      # @param trigger_variant [Symbol] select [button, icon, ghost, custom]
      def default(hoverable: false, close_on_click: true, align: :right, wide: false, trigger_variant: :button)
        render_with_template(locals: {
          hoverable: hoverable,
          close_on_click: close_on_click,
          align: align.to_sym,
          wide: wide,
          trigger_variant: trigger_variant.to_sym
        })
      end

      # Hoverable Dropdown
      # ---------------
      # Opens on hover using DaisyUI's CSS-only hover
      def hoverable
        render_with_template
      end

      # @!endgroup

      # @!group Alignments

      # Dropdown Top
      # ---------------
      # Opens above the trigger
      def top_aligned
        render_with_template
      end

      # Dropdown Bottom End
      # ---------------
      # Opens below aligned to the end
      def bottom_end_aligned
        render_with_template
      end

      # @!endgroup

      # @!group Content

      # With Custom Content
      # ---------------
      # Specify any HTML content within the block
      # @param hoverable toggle
      # @param close_on_click toggle
      # @param align [Symbol] select [left, right, top, bottom, top_end, bottom_end]
      def with_content(hoverable: false, close_on_click: true, align: :right)
        render_with_template(locals: {
          hoverable: hoverable,
          close_on_click: close_on_click,
          align: align.to_sym
        })
      end

      # Wide Dropdown
      # ---------------
      # Wider dropdown menu for more content
      def wide
        render_with_template
      end

      # @!endgroup
    end
  end
end
