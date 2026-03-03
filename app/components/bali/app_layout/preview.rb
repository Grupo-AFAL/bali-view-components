# frozen_string_literal: true

module Bali
  module AppLayout
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Full admin layout with sidebar, collapsible menu, app switcher, and bottom configuration group.
      # In production, use `fixed: true` on the SideMenu and `fixed_sidebar: true` on AppLayout for a fixed sidebar.
      # @param collapsible toggle
      # @param flash_notice text
      # @param modal toggle
      # @param drawer toggle
      def default(collapsible: true, flash_notice: "", modal: true, drawer: true)
        render_with_template(
          template: "bali/app_layout/previews/default",
          locals: {
            collapsible: collapsible,
            flash_notice: flash_notice.presence,
            modal: modal,
            drawer: drawer ? { size: :lg } : false
          }
        )
      end
    end
  end
end
