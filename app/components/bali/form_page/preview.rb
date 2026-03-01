# frozen_string_literal: true

module Bali
  module FormPage
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Form page wraps form content in a Card with consistent breadcrumbs and header.
      # Use for new/edit pages with a focused single-column form.
      def default
        render_with_template(template: "bali/form_page/previews/default")
      end

      # @label With Sidebar
      # Two-column layout: form on left, help/tips on right.
      def with_sidebar
        render_with_template(template: "bali/form_page/previews/with_sidebar")
      end
    end
  end
end
