# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
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

    private

    def build_gantt_tasks
      Movie.limit(5).map do |movie|
        start_date = movie.created_at.to_date
        end_date = movie.done? ? (start_date + rand(30..90).days) : (Date.current + rand(10..60).days)
        {
          id: movie.id, name: movie.name,
          start_date: start_date, end_date: end_date,
          progress: movie.done? ? 100 : rand(20..80),
          color: movie.done? ? 'hsl(142, 76%, 36%)' : 'hsl(38, 92%, 50%)'
        }
      end
    end

    def build_heatmap_data
      days = %w[Mon Tue Wed Thu Fri Sat Sun]
      days.index_with { |_day| (9..17).index_with { |_hour| rand(0..10) } }
    end
  end
end
