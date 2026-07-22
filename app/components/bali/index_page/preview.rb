# frozen_string_literal: true

module Bali
  module IndexPage
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Standard index page with breadcrumbs, title, action button, and body area.
      def default
        render_with_template(template: "bali/index_page/previews/default")
      end

      # @label With nav (two-level navigation)
      # Second-level navigation via the `nav` slot, rendered between the page
      # header and the body. Recipe: level 1 `Tabs style: :border` (icon+label),
      # level 2 `Tabs style: :box, size: :sm`, both with `href:` tabs.
      def with_nav
        render_with_template(template: "bali/index_page/previews/with_nav")
      end
    end
  end
end
