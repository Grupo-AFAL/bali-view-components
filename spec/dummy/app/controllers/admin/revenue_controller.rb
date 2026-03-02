# frozen_string_literal: true

module Admin
  class RevenueController < BaseController
    include DemoChartHelper

    def index
      @total_revenue = Movie.sum(:budget)
      @avg_budget = Movie.where.not(budget: nil).average(:budget)&.round(0) || 0
      @top_budget = Movie.maximum(:budget) || 0
      @funded_count = Movie.where.not(budget: nil).where("budget > 0").count
      @total_movies = Movie.count

      @revenue_by_genre = build_revenue_by_genre
      @monthly_revenue = build_monthly_data(range: 100_000..500_000, seed: 45)
      @top_movies = Movie.includes(:tenant).where.not(budget: nil).order(budget: :desc).limit(10)
      @budget_by_status = Movie.where.not(budget: nil)
                               .group(:status)
                               .sum(:budget)
                               .transform_keys(&:humanize)
    end

    private

    def build_revenue_by_genre
      Movie.where.not(budget: nil)
           .group(:genre)
           .sum(:budget)
    end
  end
end
