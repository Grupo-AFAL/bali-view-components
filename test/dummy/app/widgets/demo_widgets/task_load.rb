# frozen_string_literal: true

module DemoWidgets
  # THE TREND LADDER, the bad-news direction — and the reason `positive_when`
  # exists at all.
  #
  # More work landing next month is worse, not better. This declares
  # `positive_when :down`, so a RISING number renders red where `StudioFoundings`
  # renders the same movement green. Side by side on the dashboard, those two are
  # the argument for the field.
  class TaskLoad < Bali::Widget::TrendBase
    default_size :large

    WEEKS = 6

    # A month-wide window rather than a week: the weekly buckets the series draws
    # are ones and twos, where one task moving swings the percentage wildly, and a
    # trend computed off noise is worse than no trend.
    trend do |t|
      t.current { upcoming.count { |task| task.due_date <= Date.current + 30 } }
      t.previous do
        upcoming.count { |task| task.due_date > Date.current + 30 && task.due_date <= Date.current + 60 }
      end
      t.positive_when :down
      t.period_label "vs next month"
    end

    series do |s|
      s.labels { by_week.keys }
      s.values { by_week.values }
    end

    private

    def upcoming
      @upcoming ||= Task.includes(:project)
                        .where.not(status: :done)
                        .where(due_date: Date.current..)
                        .order(:due_date)
    end

    # Real due dates bucketed by the week they land in — a forward-looking series
    # rather than a history, which is what a workload actually is.
    def by_week
      @by_week ||= WEEKS.times.to_h do |offset|
        starts = Date.current.beginning_of_week + offset.weeks
        [ I18n.l(starts, format: :short),
          upcoming.count { |task| task.due_date&.beginning_of_week == starts } ]
      end
    end
  end
end
