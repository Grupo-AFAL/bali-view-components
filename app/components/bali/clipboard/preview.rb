# frozen_string_literal: true

module Bali
  module Clipboard
    class Preview < ApplicationViewComponentPreview
      # Clipboard
      # -------
      # To copy text to clipboard
      def default
        render Clipboard::Component.new do |c|
          c.trigger('Copy')
          c.source('Click the button to copy me!')
        end
      end

      def with_icons
        render_with_template(
          template: 'bali/clipboard/previews/with_icons'
        )
      end
    end
  end
end
