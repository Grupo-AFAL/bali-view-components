# frozen_string_literal: true

module Bali
  module AppLayout
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Full admin layout with fixed sidebar, collapsible menu, app switcher, and bottom configuration group.
      # @param collapsible toggle
      def default(collapsible: true)
        render_with_template(
          template: "bali/app_layout/previews/default",
          locals: { collapsible: collapsible }
        )
      end
    end
  end
end
