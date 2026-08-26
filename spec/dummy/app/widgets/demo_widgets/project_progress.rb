# frozen_string_literal: true

module DemoWidgets
  # THE RING LADDER: progress toward a goal, then how you got there.
  #
  # The goal REPLACES the number as the headline — `small` is the ring alone,
  # and the bigger canvases keep the ring and add the history beside or beneath
  # it. That is the whole shape of the third pattern.
  class ProjectProgress < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :large

    def call
      Bali::Widget::Result.new(
        count: done.count,
        items: rows,
        view_all_path: admin_projects_path,
        goal: Bali::Widget::Goal.new(value: done.count, max: Task.count,
                                     label: I18n.t("widgets.project_progress.of_total",
                                                   count: Task.count)),
        series: Bali::Widget::Series.new(labels: by_status.keys.map(&:humanize),
                                         values: by_status.values, type: :bar)
      )
    end

    private

    def done = @done ||= Task.where(status: :done)

    def by_status
      @by_status ||= Task.group(:status).count
    end

    def rows
      done.includes(:project).limit(PREVIEW_ROWS).map do |task|
        Bali::Widget::Row.new(title: task.title,
                              subtitle: subtitle(task.project&.name, task.priority),
                              href: admin_project_path(task.project))
      end
    end
  end
end
