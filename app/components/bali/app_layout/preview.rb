# frozen_string_literal: true

module Bali
  module AppLayout
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Full admin layout with sidebar, collapsible menu, app switcher, and bottom configuration group.
      # In production, use `fixed: true` on the SideMenu and `fixed_sidebar: true` on AppLayout for a fixed sidebar.
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
