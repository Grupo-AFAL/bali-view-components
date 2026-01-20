# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    # Stats
    @total_movies = Movie.count
    @active_productions = Movie.draft.count
    @studios_count = Tenant.count
    @indie_count = Movie.where(indie: true).count

    # Chart data - Movies by genre
    @movies_by_genre = Movie.group(:genre).count

    # Chart data - Movies by status
    @movies_by_status = Movie.group(:status).count.transform_keys(&:humanize)

    # Recent activity
    @recent_movies = Movie.includes(:tenant).order(created_at: :desc).limit(5)

    # GanttChart data - Movie production timeline (demo data)
    @gantt_tasks = build_gantt_tasks

    # Heatmap data - Movie activity by day of week and hour (demo data)
    @heatmap_data = build_heatmap_data
  end

  private

  # Build demo Gantt chart tasks from movies
  def build_gantt_tasks
    Movie.limit(5).map.with_index do |movie, _index|
      start_date = movie.created_at.to_date
      end_date = movie.done? ? (start_date + rand(30..90).days) : (Date.current + rand(10..60).days)

      {
        id: movie.id,
        name: movie.name,
        start_date: start_date,
        end_date: end_date,
        progress: movie.done? ? 100 : rand(20..80),
        color: movie.done? ? 'hsl(142, 76%, 36%)' : 'hsl(38, 92%, 50%)'
      }
    end
  end

  # Build demo heatmap data (activity by day of week)
  def build_heatmap_data
    days = %w[Mon Tue Wed Thu Fri Sat Sun]
    days.index_with do |_day|
      # Hours 9-17 (working hours) with random activity counts
      (9..17).index_with { |_hour| rand(0..10) }
    end
  end
end
