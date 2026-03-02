# frozen_string_literal: true

module Admin
  class AnalyticsController < BaseController
    DEMO_TOTAL_VIEWS = 142_857

    def index
      @stats = {
        total_movies: Movie.count,
        total_views: DEMO_TOTAL_VIEWS,
        avg_rating: Movie.average_rating,
        completion_rate: Movie.completion_rate
      }

      @movies_by_genre = Movie.by_genre_count
      @movies_by_status = Movie.by_status_count
      @top_movies = Movie.top_rated

      chart_data = DemoChartData.new
      @monthly_production = chart_data.monthly_data(range: 3..15, seed: 44)
      @heatmap_data = chart_data.heatmap_data
      @gantt_tasks = chart_data.gantt_tasks
    end
  end
end
