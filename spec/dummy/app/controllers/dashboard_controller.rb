# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    # Stats
    @total_movies = Movie.count
    @active_productions = Movie.draft.count
    @studios_count = Tenant.count
    @indie_count = Movie.indie.count

    # Chart data - Movies by genre
    @movies_by_genre = Movie.group(:genre).count

    # Chart data - Movies by status
    @movies_by_status = Movie.group(:status).count.transform_keys(&:humanize)

    # Recent activity
    @recent_movies = Movie.includes(:studio).order(created_at: :desc).limit(5)

    # Heatmap data - Movie activity by day of week and hour (demo data)
    @heatmap_data = build_heatmap_data
  end

  private

  # Build demo heatmap data (activity by day of week)
  def build_heatmap_data
    days = %w[Mon Tue Wed Thu Fri Sat Sun]
    days.index_with do |_day|
      # Hours 9-17 (working hours) with random activity counts
      (9..17).index_with { |_hour| rand(0..10) }
    end
  end
end
