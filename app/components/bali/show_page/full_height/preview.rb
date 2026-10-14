# frozen_string_literal: true

module Bali
  module ShowPage
    module FullHeight
      # A preview class of its own for the reason SplitView::FullHeight has one: AppLayout
      # renders its own `<body>`, so the scenario needs the `app_layout_preview` layout, and
      # `layout` is declared per class.
      class Preview < ApplicationViewComponentPreview
        layout "app_layout_preview"

        # @label Default
        # The body fills what the header leaves of the screen, so the composer sits at the
        # bottom however many lines the title wraps to, and the conversation scrolls inside
        # the chat. `height: 100%` and a flex chain, nothing measured: turn `viewport_locked`
        # off and there is no bounded ancestor to fill. Inert below `lg`.
        # @param height select { choices: [full, content] }
        # @param viewport_locked toggle
        # @param title text
        def default(height: :full, viewport_locked: true, title: "Discovery interview")
          render_with_template(
            template: "bali/show_page/full_height/previews/default",
            locals: { height: height.to_sym, viewport_locked: viewport_locked, title: title }
          )
        end
      end
    end
  end
end
