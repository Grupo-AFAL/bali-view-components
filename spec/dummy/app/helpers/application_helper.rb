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
      # El valor de la opción es la ETIQUETA del enum (`k`), no el entero: es la forma
      # natural de escribirlo y es exactamente la que devolvía los registros contrarios
      # antes de que Bali::FilterForm tradujera etiqueta -> valor. Queda así a propósito,
      # porque es la única cobertura end-to-end de esa traducción en el dummy. NO pasarlo
      # a `[k.humanize, v]`: eso apaga la prueba y deja el pozo abierto para las apps
      # host. El camino de los enteros ya lo cubre Studio.filter_options.
      { key: :status, label: "Status", type: :select, options: Movie.statuses.map { |k, _v| [ k.humanize, k ] } },
      { key: :created_at, label: "Created Date", type: :date },
      { key: :indie, label: "Indie Film", type: :boolean }
    ]
  end
end
