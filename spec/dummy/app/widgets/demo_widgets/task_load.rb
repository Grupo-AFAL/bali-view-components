# frozen_string_literal: true

module DemoWidgets
  # THE METRIC LADDER, the bad-news direction — and the reason `positive_when`
  # exists at all.
  #
  # More work landing next week is worse, not better, so this declares
  # `positive_when: :down` and a RISING number renders red. `StudioFoundings`
  # next door is the same ladder with the same shape and the opposite meaning:
  # side by side on the dashboard, they are the argument for the field.
  #
  # `wide` so the showcase has one card in the two-column layout: the figure and
  # its chart on the left, the breakdown on the right.
  class TaskLoad < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :wide

    WEEKS = 6

    def call
      Bali::Widget::Result.new(
        count: upcoming.count,
        items: rows,
        view_all_path: admin_projects_path,
        trend: load_trend,
        series: Bali::Widget::Series.new(labels: by_week.keys, values: by_week.values)
      )
    end

    private

    def upcoming
      @upcoming ||= Task.includes(:project)
                        .where.not(status: :done)
                        .where(due_date: Date.current..)
                        .order(:due_date)
    end

    # Real due dates, bucketed by the week they land in — a forward-looking
    # series rather than a history, which is what a workload actually is.
    def by_week
      @by_week ||= WEEKS.times.to_h do |offset|
        starts = Date.current.beginning_of_week + offset.weeks
        [ I18n.l(starts, format: :short), upcoming.count { |t| t.due_date&.beginning_of_week == starts } ]
      end
    end

    # The next month against the one after it. A month-wide window rather than a
    # week because the weekly buckets here are ones and twos, where a single task
    # moving swings the percentage wildly — a trend computed off noise is worse
    # than no trend.
    #
    # `positive_when: :down`: less work landing is GOOD, which is the opposite of
    # what `StudioFoundings` means by the same movement. Both widgets are falling
    # on this dashboard and they render in opposite colours — that pair is the
    # clearest thing the showcase can say about why the field exists.
    def load_trend
      soon = upcoming.count { |t| t.due_date <= Date.current + 30 }
      later = upcoming.count { |t| t.due_date > Date.current + 30 && t.due_date <= Date.current + 60 }
      return if soon.zero?

      Bali::Widget::Trend.new(
        delta: (((later - soon) / soon.to_f) * 100).round,
        period: I18n.t("widgets.task_load.period"),
        positive_when: :down
      )
    end

    def rows
      upcoming.limit(PREVIEW_ROWS).map do |task|
        Bali::Widget::Row.new(title: task.title,
                              subtitle: subtitle(task.project&.name, task.due_date&.to_fs(:long)),
                              href: admin_project_path(task.project))
      end
    end
  end
end
