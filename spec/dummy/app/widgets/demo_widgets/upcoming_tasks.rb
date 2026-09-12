# frozen_string_literal: true

module DemoWidgets
  class UpcomingTasks < Bali::Widget::ListBase
    include WidgetRoutes

    default_size :large

    # A BLOCK, and it has to be: a class body runs once at boot, so `Date.current`
    # in the value form is the day the process started and this tile shows the
    # wrong week until a redeploy. The reloader hides that in development.
    list do
      Task.includes(:project)
          .where.not(status: :done)
          .where(due_date: Date.current..)
          .order(:due_date)
    end

    row do |r|
      r.title :title
      r.subtitle { |task| join(task.project.name, task.priority.humanize) }
      r.href { |task| admin_project_path(task.project) }
    end
    view_all_path { admin_projects_path }
  end
end
