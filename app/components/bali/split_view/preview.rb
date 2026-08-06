# frozen_string_literal: true

module Bali
  module SplitView
    class Preview < ApplicationViewComponentPreview
      TEMPLATE = "bali/split_view/previews/default"

      # The rows link to `/split-view?selected=<id>` in the dummy app, a real page
      # that renders the same `split-view-detail` frame. Clicking one is a real
      # Turbo Frame navigation: only the right column is replaced, the master keeps
      # its scroll, and the URL advances so the selection is deep-linkable.
      #
      # Below `lg` the panes stack, master on top.
      # @param master_width [String] select ["320px", "420px", "36rem", "35%"]
      def default(master_width: "420px")
        render_with_template(
          template: Bali::SplitView::Preview::TEMPLATE,
          locals: { movies: preview_movies, selected: nil, master_width: master_width }
        )
      end

      # What the server renders for a deep link: the row already carries
      # `aria-current="true"` on first paint and the frame already holds the
      # detail. The Stimulus controller only takes over from the next click on.
      def with_selection
        movies = preview_movies

        render_with_template(
          template: Bali::SplitView::Preview::TEMPLATE,
          locals: { movies: movies, selected: movies.second, master_width: "420px" }
        )
      end

      # `advance: false` for a split view that is not a location of its own — the
      # frame still swaps, but nothing is pushed into the history.
      def without_advance
        render_with_template(
          template: Bali::SplitView::Preview::TEMPLATE,
          locals: { movies: preview_movies, selected: nil, master_width: "420px", advance: false }
        )
      end

      private

      def preview_movies
        Movie.includes(:studio).order(:name).limit(8)
      end
    end
  end
end
