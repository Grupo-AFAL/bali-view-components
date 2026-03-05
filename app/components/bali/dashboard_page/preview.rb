# frozen_string_literal: true

module Bali
  module DashboardPage
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Dashboard page with stat cards, header with actions, and body content.
      # Use for admin dashboards and overview pages.
      def default
        render_with_template(template: "bali/dashboard_page/previews/default")
      end
    end
  end
end
