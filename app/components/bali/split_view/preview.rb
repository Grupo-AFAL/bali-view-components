# frozen_string_literal: true

module Bali
  module SplitView
    class Preview < ApplicationViewComponentPreview
      STRUCTURED = "bali/split_view/previews/structured_list"
      CUSTOM_MASTER = "bali/split_view/previews/custom_master"
      FRAME_OPTIONS = "bali/split_view/previews/frame_options"

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
      def default
        render_structured
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

      # `with_group`: the same rows under headings, each with its own total. The
      # row call does not change at all — it moves from `list.with_item` to
      # `group.with_item` and takes the same keywords.
      #
      # **The listing has to be ordered by the group key.** Here that is
      # `order(:status, :name)`, and the data makes the reason visible: 3 draft
      # and 17 done over pages of five, so this page carries both headings and
      # every page the sentinel fetches afterwards is a continuation of `done` —
      # one seam, which is what the controller merges. Ordered by name instead,
      # `done` would come back on every page and the heading with it.
      def grouped_list
        render_structured(group_by: :status)
      end

      # `advance: false` for a split view that is not a location of its own — the
      # frame still swaps, but nothing is pushed into the history.
      def without_advance
        render_structured(advance: false)
      end

      # `collapsible: true`: the list takes the whole width until a row is
      # clicked; then the detail slides in beside it (300 ms) and the list
      # shrinks to its column. «Close» or Esc give the list the width back,
      # empty the frame and clear the row's highlight; focus returns to the row.
      # Below `lg` the detail is a full-screen sheet with «← Back».
      #
      # What opens it is the frame getting content — a row's Turbo Frame load
      # here, or anything an app puts in the frame — so the rows need nothing
      # new. `advance: false`: this drill-down is not a location of its own.
      #
      # `height:` and `master_width:` try the other options with it: `:screen`
      # fills to the bottom of the window, `:equal` makes the two columns the
      # same width.
      # @param height select { choices: [content, full, screen, 640px] }
      # @param master_width select { choices: [420px, equal, 50%] }
      def collapsible(height: "content", master_width: "420px")
        render_structured(advance: false, collapsible: true,
                          height: split_option(height), master_width: split_option(master_width))
      end

      # `frame_options:` writes attributes on the detail `<turbo-frame>` itself.
      # Here they make a row click scroll the detail into view while the panes
      # are stacked, below `lg`, where the detail sits under the whole list:
      # `autoscroll` and `data-autoscroll-block="start"`. Turbo reads the second
      # off the frame already in the page, never off the one in the response, so
      # nothing inside the detail could set it.
      #
      # Turbo scrolls to the frame's first child, so the detail opens with a
      # marker hidden from `lg` up: side by side, the page does not move. The
      # list is uncapped, so that page scrolls away from the detail; the frame's
      # `lg:sticky lg:top-4` keeps it beside the row clicked.
      #
      # Narrow the window below 1024px to see it scroll.
      def frame_options
        render_with_template(template: Bali::SplitView::Preview::FRAME_OPTIONS)
      end

      # The **escape hatch**: the free `master` slot, with every row attribute
      # written by hand. Still supported, and the answer for a listing `with_list`
      # cannot express — a tree, a calendar. For anything that can be a row of
      # title/subtitle/tags/meta, use `default`; for runs of those under
      # headings, `grouped_list`.
      # @param master_width [String] select ["320px", "420px", "36rem", "35%"]
      def custom_master(master_width: "420px")
        render_with_template(
          template: Bali::SplitView::Preview::CUSTOM_MASTER,
          locals: { movies: preview_movies, selected: nil, master_width: master_width }
        )
      end

      private

      def render_structured(selected: nil, filter_mode: :single, filters: nil, advance: true, group_by: nil,
                            collapsible: false, height: :content, master_width: Bali::SplitView::Component::DEFAULT_MASTER_WIDTH)
        render_with_template(
          template: Bali::SplitView::Preview::STRUCTURED,
          locals: {
            selected: selected,
            filter_mode: filter_mode,
            filters: filters || status_filters,
            advance: advance,
            group_by: group_by,
            collapsible: collapsible,
            height: height,
            master_width: master_width
          }
        )
      end

      # A select's value as the component takes it: keywords as symbols.
      def split_option(value)
        %w[equal screen full content].include?(value.to_s) ? value.to_sym : value.to_s
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
