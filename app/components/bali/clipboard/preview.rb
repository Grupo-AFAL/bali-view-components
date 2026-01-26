# frozen_string_literal: true

module Bali
  module Clipboard
    class Preview < ApplicationViewComponentPreview
      # Copy text to clipboard with visual feedback.
      #
      # Uses a Stimulus controller that shows success content for 2 seconds after copying.
      # Customize duration with `data-clipboard-success-duration-value="3000"`.
      #
      # @param source_text text "Text to copy"
      def default(source_text: 'https://example.com/api/v1/token/abc123xyz')
        render_with_template(locals: { source_text: source_text })
      end

      # Text-based trigger variant
      #
      # Uses text labels instead of icons. Useful when the copy action needs
      # to be more explicit for users.
      def with_text_labels
        render Clipboard::Component.new do |c|
          c.with_trigger('Copy')
          c.with_success_content('Copied!')
          c.with_source('Click the button to copy me!')
        end
      end

      # Long text with truncation
      #
      # Demonstrates how long text is handled with truncation in the source area.
      def long_text
        render_with_template
      end
    end
  end
end
