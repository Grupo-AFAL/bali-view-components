# frozen_string_literal: true

# Reference wiring for Bali::SplitView (#728): the whole Rails side of a
# master-detail screen in one action. `?selected=<id>` is what makes the
# selection deep-linkable — the row links carry `data-turbo-frame`, so Turbo
# swaps only the detail pane, but the same URL loaded cold renders the full page
# with that row already highlighted.
#
# The Lookbook preview of the component points its rows at this route, so the
# frame swap the preview demonstrates is a real request against a real page.
class SplitViewsController < ApplicationController
  MASTER_LIMIT = 12

  def show
    @movies = Movie.includes(:studio).order(:name).limit(MASTER_LIMIT)
    @selected = @movies.detect { |movie| movie.id == params[:selected].to_i }
  end
end
