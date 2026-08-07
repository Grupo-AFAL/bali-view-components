# frozen_string_literal: true

# Reference wiring for Bali::SplitView (#728, #971, #977): the whole Rails side
# of a master-detail screen in one action. `?selected=<id>` is what makes the
# selection deep-linkable — the row links carry `data-turbo-frame`, so Turbo
# swaps only the detail pane, but the same URL loaded cold renders the full page
# with that row already highlighted.
#
# The listing is paginated and the component's infinite scroll fetches this very
# action one page further on. There is nothing here for it: no `respond_to`, no
# format branch, no endpoint of its own. That is the point of fetch-and-extract.
#
# Filtering is a plain `?status=` in the query string, read straight off params.
# No FilterForm, no Ransack, no form object — the filter pills are links, so a
# filter is just a URL. Nothing here resets the infinite scroll either: a pill
# click is a full-page navigation, so the server renders page one and the
# sentinel picks up a next-page URL that already carries the filter.
#
# `@selected` is looked up against the whole table and not the current page, so a
# deep link to a record on page 4 renders its detail immediately. Its row is not
# on screen to highlight yet — it lights up when infinite scroll reaches its page.
class SplitViewsController < ApplicationController
  PER_PAGE = 5

  def show
    @status = params[:status].presence_in(Movie.statuses.keys)
    scope = @status ? Movie.where(status: @status) : Movie.all

    @counts = Movie.group(:status).count
    @pagy, @movies = pagy(scope.includes(:studio).order(:name), limit: PER_PAGE)
    @selected = Movie.find_by(id: params[:selected])
  end

  private

  # The href a pill points at. The active one drops the param, so clicking it
  # again clears the filter — which is what replaces a Clear button.
  helper_method def split_view_filter_path(status)
    split_view_path(status: (@status == status ? nil : status))
  end
end
