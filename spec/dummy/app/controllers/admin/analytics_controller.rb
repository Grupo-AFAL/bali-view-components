# frozen_string_literal: true

module Admin
  class AnalyticsController < BaseController
    def index
      @total_movies = Movie.count
      @total_views = rand(50_000..200_000)
      @avg_rating = Movie.where.not(rating: nil).average(:rating)&.round(1) || 0
      @completion_rate = Movie.count.zero? ? 0 : (Movie.done.count * 100.0 / Movie.count).round

      @movies_by_genre = Movie.group(:genre).count
      @movies_by_status = Movie.group(:status).count.transform_keys(&:humanize)
      @monthly_production = build_monthly_production
      @genre_ratings = build_genre_ratings
      @heatmap_data = build_heatmap_data
      @top_movies = Movie.includes(:tenant).order(rating: :desc).limit(5)
      @gantt_tasks = build_gantt_tasks
    end

    private

    def build_monthly_production
      6.downto(0).each_with_object({}) do |months_ago, hash|
        month = months_ago.months.ago.strftime("%b %Y")
        hash[month] = rand(3..15)
      end
    end

    def build_genre_ratings
      Movie.where.not(rating: nil)
           .group(:genre)
           .average(:rating)
           .transform_values { |v| v.round(1) }
    end

    def build_gantt_tasks
      Movie.limit(5).map do |movie|
        start_date = movie.created_at.to_date
        end_date = movie.done? ? (start_date + rand(30..90).days) : (Date.current + rand(10..60).days)
        {
          id: movie.id, name: movie.name,
          start_date: start_date, end_date: end_date,
          progress: movie.done? ? 100 : rand(20..80),
          color: movie.done? ? "hsl(142, 76%, 36%)" : "hsl(38, 92%, 50%)"
        }
      end
    end

    def build_heatmap_data
      days = %w[Mon Tue Wed Thu Fri Sat Sun]
      days.index_with { |_day| (9..17).index_with { |_hour| rand(0..10) } }
    end
  end
end
