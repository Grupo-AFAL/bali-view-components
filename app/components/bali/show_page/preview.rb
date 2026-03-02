# frozen_string_literal: true

module Bali
  module ShowPage
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Show page with breadcrumbs, title with tags, actions, two-column layout with sidebar.
      def default
        render_with_template(template: "bali/show_page/previews/default")
      end

      # @label Without Sidebar
      # Full-width show page without a sidebar column.
      def without_sidebar
        render_with_template(template: "bali/show_page/previews/without_sidebar")
      end
    end
  end
end
