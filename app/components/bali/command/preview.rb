# frozen_string_literal: true

module Bali
  module Command
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Command palette with grouped pages, recents, and quick actions.
      # Click the trigger or press ⌘K (Mac) / Ctrl+K to open.
      def default
        render_with_template(template: "bali/command/previews/default")
      end

      # @label Compact density
      # Tighter rows for power users / dense workspaces.
      def compact
        render_with_template(template: "bali/command/previews/compact")
      end
    end
  end
end
