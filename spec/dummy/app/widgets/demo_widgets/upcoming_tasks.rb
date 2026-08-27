# frozen_string_literal: true

module DemoWidgets
  class UpcomingTasks < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :large

    order_by :due_date
    row_title :title
    row_subtitle { |task| subtitle(task.project.name, task.priority.humanize) }
    row_href { |task| admin_project_path(task.project) }
    view_all_path { admin_projects_path }

    def scope
      Task.includes(:project).where.not(status: :done).where(due_date: Date.current..)
    end
  end
end
