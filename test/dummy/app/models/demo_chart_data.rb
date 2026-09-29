# frozen_string_literal: true

class DemoChartData
  HEATMAP_SEED = 43

  def heatmap_data
    rng = Random.new(HEATMAP_SEED)
    days = %w[Mon Tue Wed Thu Fri Sat Sun]
    days.index_with { |_day| (9..17).index_with { |_hour| rng.rand(0..10) } }
  end

  def monthly_data(range:, seed: 44)
    rng = Random.new(seed)
    6.downto(0).each_with_object({}) do |months_ago, hash|
      month = months_ago.months.ago.strftime("%b %Y")
      hash[month] = rng.rand(range)
    end
  end
end
