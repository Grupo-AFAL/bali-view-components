# frozen_string_literal: true

module ApplicationHelper
  # Pagy 43+ no longer requires Pagy::Frontend include
  # Helper methods are now available on the Pagy instance directly
  include Bali::ApplicationHelper
  include Bali::FormHelper

  def distribution_rows(data, colors: %i[primary secondary accent info success warning error])
    total = data.values.sum.to_f
    data.sort_by { |_, v| -v }.each_with_index.map do |(label, amount), i|
      { label: label, amount: amount, pct: total.positive? ? (amount / total * 100).round : 0, color: colors[i % colors.length] }
    end
  end

  def movie_filter_attributes
    genres = Movie.distinct.pluck(:genre).compact.sort.map { |g| [ g, g ] }
    studios = Tenant.order(:name).pluck(:name, :id)
    [
      { key: :name, label: "Name", type: :text },
      { key: :genre, label: "Genre", type: :select, options: genres },
      { key: :tenant_id, label: "Studio", type: :select, options: studios },
      { key: :status, label: "Status", type: :select, options: Movie.statuses.map { |k, _v| [ k.humanize, k ] } },
      { key: :created_at, label: "Created Date", type: :date },
      { key: :indie, label: "Indie Film", type: :boolean }
    ]
  end
end
