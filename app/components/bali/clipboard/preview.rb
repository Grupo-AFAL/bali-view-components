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
      # @param use_icons toggle "Use icons instead of text labels"
      def default(source_text: 'Click the button to copy me!', use_icons: false)
        render Clipboard::Component.new do |c|
          if use_icons
            c.with_trigger { render Bali::Icon::Component.new('copy') }
            c.with_success_content { render Bali::Icon::Component.new('check', class: 'text-success') }
          else
            c.with_trigger('Copy')
          end
          c.with_source(source_text)
        end
      end
    end
  end
end
