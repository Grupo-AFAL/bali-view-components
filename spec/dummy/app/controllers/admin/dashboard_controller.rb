# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    include DemoChartHelper

    def index
      @total_movies = Movie.count
      @active_productions = Movie.draft.count
      @studios_count = Tenant.count
      @indie_count = Movie.where(indie: true).count
      @movies_by_genre = Movie.by_genre_count
      @movies_by_status = Movie.by_status_count
      @recent_movies = Movie.includes(:tenant).order(created_at: :desc).limit(5)
      @gantt_tasks = build_gantt_tasks
      @heatmap_data = build_heatmap_data
    end
  end
end
