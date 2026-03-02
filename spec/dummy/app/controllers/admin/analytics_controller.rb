# frozen_string_literal: true

module Admin
  class AnalyticsController < BaseController
    DEMO_TOTAL_VIEWS = 142_857

    def index
      total_movies = Movie.count

      @stats = {
        total_movies: total_movies,
        total_views: DEMO_TOTAL_VIEWS,
        avg_rating: Movie.average_rating,
        completion_rate: total_movies.zero? ? 0 : (Movie.done.count * 100.0 / total_movies).round
      }

      @movies_by_genre = Movie.by_genre_count
      @movies_by_status = Movie.by_status_count
      @monthly_production = DemoChartData.new.monthly_data(range: 3..15, seed: 44)
      @heatmap_data = DemoChartData.new.heatmap_data
      @top_movies = Movie.includes(:studio).order(rating: :desc).limit(5)
      @gantt_tasks = DemoChartData.new.gantt_tasks
    end
  end
end
