# frozen_string_literal: true

module Bali
  module Command
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Command palette with grouped pages, recents, and quick actions.
      # The search-well trigger is the component's own default — no slot needed.
      # Click it or press ⌘K (Mac) / Ctrl+K to open — and the hint on the
      # trigger says whichever of the two this machine actually has.
      def default
        render_with_template(template: "bali/command/previews/default")
      end

      # @label Compact density
      # Tighter rows for power users / dense workspaces.
      def compact
        render_with_template(template: "bali/command/previews/compact")
      end

      # @label Custom trigger
      # The `with_trigger` slot replaces the default search well — for shapes
      # the default cannot be, like an icon-only toolbar button. The slot
      # content is the whole trigger: bring your own accessible name.
      def custom_trigger
        render_with_template(template: "bali/command/previews/custom_trigger")
      end
    end
  end
end
