# frozen_string_literal: true

module Bali
  module SplitView
    class Preview < ApplicationViewComponentPreview
      TEMPLATE = "bali/split_view/previews/default"
      LIST_TEMPLATE = "bali/split_view/previews/structured_list"

      PER_PAGE = 5

      # The recommended way to build a master: `with_list` + `with_item`. The
      # component writes `data-turbo-frame`, `data-split-view-target`,
      # `data-action` and `aria-current` itself, so a row template says what a row
      # *is* and never how it is wired.
      #
      # Paging is infinite: scroll the list to the bottom and the next page is
      # fetched from the dummy's `/split-view` — the same index URL one page
      # further on, with no endpoint of its own. Pagination controls are rendered
      # underneath for a reader without JavaScript; the controller hides them when
      # it connects.
      def structured_list
        render_with_template(
          template: Bali::SplitView::Preview::LIST_TEMPLATE,
          locals: {
            movies: Movie.includes(:studio).order(:name).limit(Bali::SplitView::Preview::PER_PAGE),
            total: Movie.count,
            selected: nil,
            pagy: Pagy::Offset.new(count: Movie.count, page: 1, limit: Bali::SplitView::Preview::PER_PAGE)
          }
        )
      end

      # A deep link to a record that is not on the first page. The detail renders
      # immediately — the server looks the record up against the whole table — while
      # its row is simply not on screen yet. The highlight appears when infinite
      # scroll reaches the page it lives on.
      def deep_link_beyond_the_first_page
        render_with_template(
          template: Bali::SplitView::Preview::LIST_TEMPLATE,
          locals: {
            movies: Movie.includes(:studio).order(:name).limit(Bali::SplitView::Preview::PER_PAGE),
            total: Movie.count,
            selected: Movie.order(:name).offset(Bali::SplitView::Preview::PER_PAGE + 1).first,
            pagy: Pagy::Offset.new(count: Movie.count, page: 1, limit: Bali::SplitView::Preview::PER_PAGE)
          }
        )
      end

      # The escape hatch: the free `master` slot, with the row wiring written by
      # hand. Still supported, and what a listing that `with_list` does not fit
      # should use.
      #
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
