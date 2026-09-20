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
      # The option's value is the enum's LABEL (`k`), not the integer: it is the natural way
      # to write it and it is exactly the one that returned the opposite records before
      # Bali::FilterForm translated label -> value. It stays this way on purpose, because it
      # is the only end-to-end coverage of that translation in the dummy. Do NOT change it
      # to `[k.humanize, v]`: that switches the test off and leaves the pit open for the host
      # apps. The integer path is already covered by Studio.filter_options.
      { key: :status, label: "Status", type: :select, options: Movie.statuses.map { |k, _v| [ k.humanize, k ] } },
      { key: :created_at, label: "Created Date", type: :date },
      { key: :indie, label: "Indie Film", type: :boolean }
    ]
  end
end
