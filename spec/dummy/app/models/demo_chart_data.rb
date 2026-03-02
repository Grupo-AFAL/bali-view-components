# frozen_string_literal: true

class DemoChartData
  def gantt_tasks(limit: 5)
    rng = Random.new(42)
    Movie.limit(limit).map do |movie|
      start_date = movie.created_at.to_date
      end_date = movie.done? ? (start_date + rng.rand(30..90).days) : (Date.current + rng.rand(10..60).days)
      {
        id: movie.id, name: movie.name,
        start_date: start_date, end_date: end_date,
        progress: movie.done? ? 100 : rng.rand(20..80),
        color: movie.done? ? "hsl(142, 76%, 36%)" : "hsl(38, 92%, 50%)"
      }
    end
  end

  def heatmap_data
    rng = Random.new(43)
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
