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
# `@selected` is looked up against the whole table and not the current page, so a
# deep link to a record on page 4 renders its detail immediately. Its row is not
# on screen to highlight yet — it lights up when infinite scroll reaches its page.
class SplitViewsController < ApplicationController
  PER_PAGE = 5

  def show
    # `limit:` and not `items:` — Pagy renamed it, and the old name is ignored in
    # silence, so an `items:` here paginated at the default 10 and the listing
    # quietly had only two pages.
    @pagy, @movies = pagy(Movie.includes(:studio).order(:name), limit: PER_PAGE)
    @selected = Movie.find_by(id: params[:selected])
  end
end
