# frozen_string_literal: true

module Bali
  module Reveal
    class Preview < ApplicationViewComponentPreview
      # @param opened toggle
      # @param show_border toggle
      def default(opened: false, show_border: true)
        render_with_template(locals: { opened: opened, show_border: show_border })
      end

      # @param opened toggle
      # @param show_border toggle
      def with_icon_and_title(opened: false, show_border: true)
        render_with_template(
          template: 'bali/reveal/previews/with_icon_and_title',
          locals: { opened: opened, show_border: show_border }
        )
      end
    end
  end
end
