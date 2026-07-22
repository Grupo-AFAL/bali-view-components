# frozen_string_literal: true

module Bali
  module IndexPage
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Standard index page with breadcrumbs, title, action button, and body area.
      def default
        render_with_template(template: "bali/index_page/previews/default")
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
