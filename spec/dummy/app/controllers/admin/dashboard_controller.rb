# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        total_movies: Movie.count,
        active_productions: Movie.draft.count,
        studios_count: Tenant.count,
        indie_count: Movie.where(indie: true).count
      }
      @movies_by_genre = Movie.by_genre_count
      @recent_movies = Movie.includes(:studio).order(created_at: :desc).limit(5)
    end
  end
end
