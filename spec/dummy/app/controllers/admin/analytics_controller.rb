# frozen_string_literal: true

module Admin
  class AnalyticsController < BaseController
    include DemoChartData

    def index
      @total_movies = Movie.count
      @total_views = 142_857
      @avg_rating = Movie.where.not(rating: nil).average(:rating)&.round(1) || 0
      @completion_rate = @total_movies.zero? ? 0 : (Movie.done.count * 100.0 / @total_movies).round

      @movies_by_genre = Movie.group(:genre).count
      @movies_by_status = Movie.group(:status).count.transform_keys(&:humanize)
      @monthly_production = build_monthly_data(range: 3..15, seed: 44)
      @genre_ratings = build_genre_ratings
      @heatmap_data = build_heatmap_data
      @top_movies = Movie.includes(:tenant).order(rating: :desc).limit(5)
      @gantt_tasks = build_gantt_tasks
    end

    private

    def build_genre_ratings
      Movie.where.not(rating: nil)
           .group(:genre)
           .average(:rating)
           .transform_values { |v| v.round(1) }
    end
  end
end
