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
# Filtering is query params read straight off `params`. No FilterForm, no
# Ransack, no form object — the pills are links, so a filter is a URL, and the
# component builds those URLs itself from the current request. Nothing here
# resets the infinite scroll either: a pill click is a full-page navigation, so
# the server renders page one and the sentinel picks up a next-page URL that
# already carries the filter.
#
# `@selected` is looked up against the whole table and not the current page, so a
# deep link to a record on page 4 renders its detail immediately. Its row is not
# on screen to highlight yet — it lights up when infinite scroll reaches its page.
class SplitViewsController < ApplicationController
  PER_PAGE = 5

  # AppLayout renders its own <body>, so the shell around it must not have one.
  layout "app_layout_preview", only: :full

  def show
    # A real screen picks one semantics and stays there. This page takes it from
    # a param so the reference can show both: `:single` is the bucket strip
    # (status, one value at a time) and `:multi` the independent toggles (genre,
    # several at once over `q[genre_in][]`).
    @filter_mode = params[:filter_mode] == "multi" ? :multi : :single

    @pagy, @movies = pagy(filtered.includes(:studio).order(:name), limit: PER_PAGE)
    @selected = Movie.find_by(id: params[:selected])
  end

  # The same listing, in the arrangement `height: :full` is built for: inside an
  # AppLayout that locks the viewport, so the split fills the screen and each
  # pane scrolls on its own instead of the page scrolling as a whole.
  def full
    show
    render :full
  end

  private

  def filtered
    @filter_mode == :multi ? by_genres : by_status
  end

  def by_status
    @status = params[:status].presence_in(Movie.statuses.keys)
    @counts = Movie.group(:status).count
    @status ? Movie.where(status: @status) : Movie.all
  end

  def by_genres
    @genres = Array(params.dig(:q, :genre_in)).select { |g| g.in?(Movie::GENRES) }
    @counts = Movie.group(:genre).count
    @genres.any? ? Movie.where(genre: @genres) : Movie.all
  end
end
