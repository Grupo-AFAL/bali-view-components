# frozen_string_literal: true

module Bali
  module Frame
    class Preview < ApplicationViewComponentPreview
      # A frame with its own content: the block is the frame's content. The loading
      # placeholder appears when something reloads the frame (a link with
      # `data-turbo-frame` pointing here, or a "Refresh" button).
      # @param text text
      def default(text: "Loading…")
        render Frame::Component.new(id: "frame-preview-default", text: text) do
          "Content loaded from the frame."
        end
      end

      # @label Loading state
      # The placeholder shown while the frame is `[busy]` —the first deferred load
      # or a reload targeted at the frame—. Here `[busy]` is forced so it can be
      # seen without a backend answering the `src`.
      def loading_state
        render_with_template
      end
    end
  end
end
