# frozen_string_literal: true

module Bali
  module Dropdown
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Dropdown
      # ---------------
      # Dropdown with a list of items. Trigger supports multiple variants:
      # - `:button` (default) - Standard button
      # - `:outline` - Bordered button (the toolbar control chrome)
      # - `:icon` - Ghost button with circle (for icon-only triggers)
      # - `:ghost` - Ghost button (transparent background)
      # - `:custom` - No base classes (fully customizable)
      # @param hoverable toggle
      # @param close_on_click toggle
      # @param popover toggle
      # @param align [Symbol] select [start, center, end]
      # @param direction [Symbol] select [~, top, bottom, left, right]
      # @param width [Symbol] select [sm, md, lg, xl]
      # @param trigger_variant [Symbol] select [button, outline, icon, ghost, custom]
      # rubocop:disable Metrics/ParameterLists
      def default(hoverable: false, close_on_click: true, popover: false, align: :start,
                  direction: nil, width: :md, trigger_variant: :button)
        # rubocop:enable Metrics/ParameterLists
        render_with_template(locals: {
          hoverable: hoverable,
          close_on_click: close_on_click,
          popover: popover,
          align: align.to_sym,
          direction: direction.presence&.to_sym,
          width: width.to_sym,
          trigger_variant: trigger_variant.to_sym
        })
      end

      # Hoverable Dropdown
      # ---------------
      # Opens on daisyUI's CSS-only hover. It carries the Stimulus controller now, so its
      # trigger reports `aria-expanded` and the arrow keys and Escape work — the CSS opens
      # it, the controller narrates it.
      def hoverable
        render_with_template
      end

      # Popover Mode
      # ---------------
      # The same menu, moved into a popper on `<body>` so no ancestor's `overflow` can clip
      # it — the case a dropdown inside a scrollable table always hits. The keyboard is not
      # a second implementation: the menu element is MOVED rather than copied, so the same
      # controller drives the same list from the top layer.
      def popover
        render_with_template
      end

      # @!endgroup

      # @!group Alignments

      # Direction Top
      # ---------------
      # `direction:` is the side the menu opens towards. It composes with `align:`; the two
      # used to be folded into one keyword that could spell four of the twelve pairs.
      def top_aligned
        render_with_template
      end

      # Bottom + End
      # ---------------
      # `direction: :bottom, align: :end` — what `align: :bottom_end` used to spell.
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
      # @param align [Symbol] select [start, center, end]
      def with_content(hoverable: false, close_on_click: true, align: :end)
        render_with_template(locals: {
          hoverable: hoverable,
          close_on_click: close_on_click,
          align: align.to_sym
        })
      end

      # Widest Menu
      # ---------------
      # `width: :xl` (w-80) — what the boolean `wide: true` used to spell. The scale is
      # `:sm` (w-40), `:md` (w-52, the default), `:lg` (w-64), `:xl` (w-80).
      def wide
        render_with_template
      end

      # @!endgroup
    end
  end
end
