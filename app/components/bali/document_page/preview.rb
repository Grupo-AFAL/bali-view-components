# frozen_string_literal: true

module Bali
  module DocumentPage
    class Preview < ApplicationViewComponentPreview
      # @param title text "Document title"
      # @param subtitle text "Subtitle text"
      def default(title: "Q2 2026 Product Roadmap", subtitle: "Last edited 2 hours ago")
        render_with_template(locals: { title: title, subtitle: subtitle })
      end
    end
  end
end
