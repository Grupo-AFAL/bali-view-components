# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @total_movies = Movie.count
      @active_productions = Movie.draft.count
      @studios_count = Tenant.count
      @indie_count = Movie.where(indie: true).count
      @movies_by_genre = Movie.by_genre_count
      @movies_by_status = Movie.by_status_count
      @recent_movies = Movie.includes(:tenant).order(created_at: :desc).limit(5)
      @gantt_tasks = demo_charts.gantt_tasks
      @heatmap_data = demo_charts.heatmap_data
    end

    private

    def demo_charts
      @demo_charts ||= DemoChartData.new
    end
  end
end
