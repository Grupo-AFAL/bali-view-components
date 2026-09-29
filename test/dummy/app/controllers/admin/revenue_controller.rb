# frozen_string_literal: true

module Admin
  class RevenueController < BaseController
    def index
      @stats = {
        total_revenue: Movie.sum(:budget),
        avg_budget: Movie.budgeted.average(:budget)&.round(0) || 0,
        top_budget: Movie.maximum(:budget) || 0,
        funded_count: Movie.budgeted.count,
        total_movies: Movie.count
      }

      @revenue_by_genre = Movie.budget_by_genre
      @monthly_revenue = DemoChartData.new.monthly_data(range: 100_000..500_000, seed: 45)
      @top_movies = Movie.budgeted.includes(:studio).order(budget: :desc).limit(10)
      @budget_by_status = Movie.budget_by_status
    end
  end
end
