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

      # @label With Back Button
      # Nested index page (e.g. a resource's sub-listing) with a back link to
      # its parent, same contract as ShowPage/FormPage (#639).
      def with_back
        render_with_template(template: "bali/index_page/previews/with_back")
      end
    end
  end
end
