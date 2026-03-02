# frozen_string_literal: true

module AdminHelper
  def distribution_rows(data, colors: %i[primary secondary accent info success warning error])
    total = data.values.sum.to_f
    data.sort_by { |_, v| -v }.each_with_index.map do |(label, amount), i|
      { label: label, amount: amount, pct: total.positive? ? (amount / total * 100).round : 0, color: colors[i % colors.length] }
    end
  end
end
