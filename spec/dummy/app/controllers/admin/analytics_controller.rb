# frozen_string_literal: true

module Admin
  class AnalyticsController < BaseController
    DEMO_TOTAL_VIEWS = 142_857

    def index
      @total_movies = Movie.count
      @total_views = DEMO_TOTAL_VIEWS
      @avg_rating = Movie.average_rating
      @completion_rate = @total_movies.zero? ? 0 : (Movie.done.count * 100.0 / @total_movies).round

      @movies_by_genre = Movie.by_genre_count
      @movies_by_status = Movie.by_status_count
      @monthly_production = demo_charts.monthly_data(range: 3..15, seed: 44)
      @genre_ratings = Movie.ratings_by_genre
      @heatmap_data = demo_charts.heatmap_data
      @top_movies = Movie.includes(:tenant).order(rating: :desc).limit(5)
      @gantt_tasks = demo_charts.gantt_tasks
    end

    private

    def demo_charts
      @demo_charts ||= DemoChartData.new
    end
  end
end
