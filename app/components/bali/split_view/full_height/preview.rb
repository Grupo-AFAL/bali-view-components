# frozen_string_literal: true

module Bali
  module SplitView
    module FullHeight
      # `height: :full` gets a preview class of its own for one reason: it needs a
      # layout the other scenarios must not have.
      #
      # AppLayout renders its own `<body>`, and the ordinary preview layout
      # already has one — nest them and the HTML parser discards the inner tag,
      # taking `app-layout--viewport-locked` with it. Measured: the scenario then
      # filled a 769px `<main>` inside an 1151px viewport and looked plausible
      # while demonstrating nothing. `layout` is a class-level declaration in
      # ViewComponent and Lookbook 2.3 has no per-scenario tag for it, so the
      # scenario that needs a different layout needs a different class.
      class Preview < ApplicationViewComponentPreview
        layout "app_layout_preview"

        # The split fills the screen and **each pane scrolls on its own** — the
        # inbox shape. It is `height: 100%` plus a flex chain: no measured offset,
        # no `calc(100vh - …)`, no JavaScript. So it needs an ancestor with a
        # definite height and fills nothing without one, which is why this
        # scenario renders the whole pairing rather than a bare component.
        #
        # Inert below `lg`, where the panes stack and cannot both fill one screen.
        #
        # The same arrangement, wired end to end, is at **`/split-view/full`** in
        # the dummy app.
        def default
          render_with_template(
            template: "bali/split_view/full_height/previews/default",
            locals: {
              movies: Movie.includes(:studio).order(:name).limit(8),
              total: Movie.count,
              selected: Movie.order(:name).first
            }
          )
        end
      end
    end
  end
end
