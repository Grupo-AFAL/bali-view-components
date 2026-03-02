# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    include DemoChartData

    def index
      @total_movies = Movie.count
      @active_productions = Movie.draft.count
      @studios_count = Tenant.count
      @indie_count = Movie.where(indie: true).count
      @movies_by_genre = Movie.group(:genre).count
      @movies_by_status = Movie.group(:status).count.transform_keys(&:humanize)
      @recent_movies = Movie.includes(:tenant).order(created_at: :desc).limit(5)
      @gantt_tasks = build_gantt_tasks
      @heatmap_data = build_heatmap_data
    end
  end
end
