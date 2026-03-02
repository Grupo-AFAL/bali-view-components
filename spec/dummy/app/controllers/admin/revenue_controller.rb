# frozen_string_literal: true

module Admin
  class RevenueController < BaseController
    def index
      @total_revenue = Movie.sum(:budget)
      @avg_budget = Movie.where.not(budget: nil).average(:budget)&.round(0) || 0
      @top_budget = Movie.maximum(:budget) || 0
      @funded_count = Movie.where.not(budget: nil).where("budget > 0").count

      @revenue_by_genre = build_revenue_by_genre
      @monthly_revenue = build_monthly_revenue
      @top_movies = Movie.where.not(budget: nil).order(budget: :desc).limit(10)
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

    def build_monthly_revenue
      6.downto(0).each_with_object({}) do |months_ago, hash|
        month = months_ago.months.ago.strftime("%b %Y")
        hash[month] = rand(100_000..500_000)
      end
    end
  end
end
