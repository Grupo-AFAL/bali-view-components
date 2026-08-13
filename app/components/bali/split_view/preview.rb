# frozen_string_literal: true

module Bali
  module SplitView
    class Preview < ApplicationViewComponentPreview
      STRUCTURED = "bali/split_view/previews/structured_list"
      CUSTOM_MASTER = "bali/split_view/previews/custom_master"

      PER_PAGE = 5

      # Master-detail: a list on the left, the detail of the selected row on the
      # right inside a Turbo Frame, so a row click swaps only the right column and
      # the list keeps its scroll and its highlight.
      #
      # `with_list` + `with_item` are the way to build the master: the component
      # writes `data-turbo-frame`, `data-split-view-target`, `data-action` and
      # `aria-current` itself, so the template says what a row *is* and never how
      # it is wired.
      #
      # **The filter pills are live.** They take `param:`/`value:` and build their
      # own URLs from the current request, so clicking one really filters the list
      # below — one value at a time, and clicking the active pill clears it, which
      # is what replaces a Clear button.
      #
      # The full flow — frame swaps, infinite scroll against a real paginated
      # index, deep links, back and forward — is at **`/split-view`** in the dummy
      # app. A preview cannot page against itself.
      # @param status [String] select ["", "draft", "done"]
      def default(status: "")
        render_structured(status: status)
      end

      # `filter_mode: :multi`: each pill toggles independently over a multi-valued
      # param, so several are active at once. Click two and both light up; click
      # an active one and it removes **its** value and leaves the others alone.
      #
      # The state is announced differently here on purpose. `aria-current` marks
      # "the current item of a set" and there is no single current item in this
      # mode, so the active pills carry an `sr-only` note instead — and never
      # `aria-pressed`, which browsers drop on a link. See the component docstring.
      def multi_filters
        render_structured(filter_mode: :multi, filters: genre_filters)
      end

      # What the server renders for a deep link: the row already carries
      # `aria-current="true"` on first paint and the frame already holds the
      # detail. The Stimulus controller only takes over from the next click on.
      def with_selection
        render_structured(selected: Movie.order(:name).second)
      end

      # A deep link to a record that is not on the first page. The detail renders
      # immediately — the server looks the record up against the whole table —
      # while its row is simply not on screen yet. The highlight appears when
      # infinite scroll reaches the page it lives on.
      def deep_link_beyond_the_first_page
        render_structured(selected: Movie.order(:name).offset(Bali::SplitView::Preview::PER_PAGE + 1).first)
      end

      # `advance: false` for a split view that is not a location of its own — the
      # frame still swaps, but nothing is pushed into the history.
      def without_advance
        render_structured(advance: false)
      end

      # The **escape hatch**: the free `master` slot, with every row attribute
      # written by hand. Still supported, and the answer for a listing `with_list`
      # cannot express — a tree, a calendar, a grouped inbox. For anything that
      # can be a row of title/subtitle/tags/meta, use `default`.
      # @param master_width [String] select ["320px", "420px", "36rem", "35%"]
      def custom_master(master_width: "420px")
        render_with_template(
          template: Bali::SplitView::Preview::CUSTOM_MASTER,
          locals: { movies: preview_movies, selected: nil, master_width: master_width }
        )
      end

      private

      def render_structured(scope: Movie.all, status: "", selected: nil, filter_mode: :single,
                            filters: nil, advance: true)
        scope = scope.where(status: status) if status.present?

        render_with_template(
          template: Bali::SplitView::Preview::STRUCTURED,
          locals: {
            scope: scope,
            selected: selected,
            filter_mode: filter_mode,
            filters: filters || status_filters,
            advance: advance
          }
        )
      end

      def status_filters
        counts = Movie.group(:status).count
        Movie.statuses.keys.map do |status|
          { label: status.humanize, param: :status, value: status, count: counts[status].to_i }
        end
      end

      def genre_filters
        counts = Movie.group(:genre).count
        Movie::GENRES.first(6).map do |genre|
          { label: genre, param: "q[genre_in]", value: genre, count: counts[genre].to_i }
        end
      end

      def preview_movies
        Movie.includes(:studio).order(:name).limit(8)
      end
    end
  end
end
