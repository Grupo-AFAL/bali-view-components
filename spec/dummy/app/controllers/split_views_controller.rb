# frozen_string_literal: true

# Reference wiring for Bali::SplitView (#728, #971): the whole Rails side of a
# master-detail screen in one action. `?selected=<id>` is what makes the
# selection deep-linkable — the row links carry `data-turbo-frame`, so Turbo
# swaps only the detail pane, but the same URL loaded cold renders the full page
# with that row already highlighted.
#
# The listing is paginated and the component's infinite scroll fetches this very
# action one page further on. There is nothing here for it: no `respond_to`, no
# format branch, no endpoint of its own. That is the point of fetch-and-extract.
#
# Filtering is an ordinary GET too. Nothing here resets the infinite scroll
# either — a filter submit is a full-page navigation, so the server renders page
# one and the sentinel picks up a next-page URL that already carries `q`.
#
# `@selected` is looked up against the whole table and not the current page, so a
# deep link to a record on page 4 renders its detail immediately. Its row is not
# on screen to highlight yet — it lights up when infinite scroll reaches its page.
class SplitViewsController < ApplicationController
  PER_PAGE = 5

  def show
    @filter_form = Bali::FilterForm.new(
      Movie.all,
      params,
      # `:radio_group` + `auto_submit` is the pill that filters on click (#725) —
      # the same control gc's inbox uses for its buckets, and the reason SplitView
      # grows no filtering of its own.
      simple_filters: [
        { attribute: :genre, collection: genre_options, label: "Género",
          type: :radio_group, auto_submit: true },
        # `status` and not only `genre` because every genre fits in one page: a
        # filter whose result still spans pages is the only one that can show the
        # sentinel inheriting the filter params.
        { attribute: :status, collection: status_options, label: "Estado",
          type: :radio_group, auto_submit: true }
      ]
    )

    @pagy, @movies = pagy(@filter_form.result.includes(:studio).order(:name), limit: PER_PAGE)
    @selected = Movie.find_by(id: params[:selected])
  end

  private

  # Counts live in the label because SimpleFilters does not count, and teaching it
  # to would be a filtering system of Bali's own. gc does the same thing.
  def genre_options
    Movie.group(:genre).count.sort.map { |genre, count| [ "#{genre} (#{count})", genre ] }
  end

  def status_options
    counts = Movie.group(:status).count
    Movie.statuses.map { |name, value| [ "#{name.humanize} (#{counts[name].to_i})", value ] }
  end
end
