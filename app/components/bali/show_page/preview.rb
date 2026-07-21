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

      # @label With Many Actions
      # Long title, long subtitle, and 4 actions. At narrow viewports (<640px)
      # the actions bar stacks below the title/subtitle instead of overlapping it (#625).
      def with_many_actions
        render_with_template(template: "bali/show_page/previews/with_many_actions")
      end
    end
  end
end
