# frozen_string_literal: true

module DemoWidgets
  class UpcomingTasks < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :large

    # A BLOCK, because `Date.current` in a class body is the day the process
    # booted. The other three widgets here close over nothing time-dependent.
    list(order_by: :due_date) do
      Task.includes(:project).where.not(status: :done).where(due_date: Date.current..)
    end

    row_title :title
    row_subtitle { |task| subtitle(task.project.name, task.priority.humanize) }
    row_href { |task| admin_project_path(task.project) }
    view_all_path { admin_projects_path }
  end
end
