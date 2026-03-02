# frozen_string_literal: true

module Admin
  class RevenueController < BaseController
    def index
      @total_revenue = Movie.sum(:budget)
      @avg_budget = Movie.where.not(budget: nil).average(:budget)&.round(0) || 0
      @top_budget = Movie.maximum(:budget) || 0
      @funded_count = Movie.budgeted.count
      @total_movies = Movie.count

      @revenue_by_genre = Movie.budget_by_genre
      @monthly_revenue = demo_charts.monthly_data(range: 100_000..500_000, seed: 45)
      @top_movies = Movie.includes(:tenant).where.not(budget: nil).order(budget: :desc).limit(10)
      @budget_by_status = Movie.budget_by_status
    end

    private

    def demo_charts
      @demo_charts ||= DemoChartData.new
    end
  end
end
