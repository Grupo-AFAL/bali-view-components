# frozen_string_literal: true

module Bali
  module FeedbackWidget
    # @label FeedbackWidget
    # Floating feedback button that opens a drawer with an embedded Opina iframe.
    # Polls a badge endpoint to show unread count.
    #
    # ## Requirements
    # - An Opina instance with a valid project and shared secret
    # - Stimulus controller `feedback-widget`
    #
    # **Note:** In this preview the iframe will not load (fake URL),
    # but you can interact with the floating button and drawer.
    #
    # The panel is a composed `Bali::Drawer`, so it is a native `<dialog>`. The
    # embed token is not in the frame's URL: it is sent with `postMessage` once
    # the frame loads. `spec/dummy`'s `/feedback-widget-demo` is where that round
    # trip can actually be seen, since it points the widget at a stand-in embed
    # page on the same origin.
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Click the floating button in the bottom-right corner to open the drawer.
      # Uses the `secret:` API to generate the embed token automatically.
      def default
        render FeedbackWidget::Component.new(
          project_slug: "demo-project",
          opina_url: "https://opina-demo.example.com",
          secret: "preview-secret",
          user_id: "preview-user",
          email: "preview@example.com"
        )
      end
    end
  end
end
