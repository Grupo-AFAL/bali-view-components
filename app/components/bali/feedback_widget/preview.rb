# frozen_string_literal: true

module Bali
  module FeedbackWidget
    # @label FeedbackWidget
    # Feedback button that opens a drawer with an embedded Opina iframe — floating by
    # default, or in place in a Topbar with `trigger: :icon` or `trigger: :labeled`.
    # Polls a badge endpoint to show unread count.
    #
    # ## Requirements
    # - An Opina instance with a valid project and shared secret
    # - Stimulus controller `feedback-widget`
    #
    # **Note:** In this preview the iframe will not load (fake URL),
    # but you can interact with the button and the drawer.
    #
    # The panel is a composed `Bali::Drawer`, so it is a native `<dialog>`. The
    # embed token is not in the frame's URL: it is sent with `postMessage` once
    # the frame loads. `test/dummy`'s `/feedback-widget-demo` is where that round
    # trip can actually be seen, since it points the widget at a stand-in embed
    # page on the same origin.
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Click the floating button in the bottom-right corner to open the drawer.
      # Uses the `secret:` API to generate the embed token automatically.
      def default
        render Bali::FeedbackWidget::Component.new(
          project_slug: "demo-project",
          opina_url: "https://opina-demo.example.com",
          secret: "preview-secret",
          user_id: "preview-user",
          email: "preview@example.com"
        )
      end

      # @label In Topbar: icon
      # `trigger: :icon` inside `Bali::Topbar`'s `with_action`: a round primary button the
      # height of the other actions, with the unread count in its corner.
      def topbar_icon
        render_with_template(template: "bali/feedback_widget/previews/in_topbar", locals: { trigger: :icon })
      end

      # @label In Topbar: icon and text
      # `trigger: :labeled`: the icon and the panel's title, with the unread count beside them.
      # Below `sm` the text goes and the button is the icon alone.
      def topbar_labeled
        render_with_template(template: "bali/feedback_widget/previews/in_topbar", locals: { trigger: :labeled })
      end
    end
  end
end
