# frozen_string_literal: true

module DemoWidgets
  # `large` fits 7 rows, so this is the widget that actually needs a longer
  # scope to show off the size — every task due today or later, project first.
  class UpcomingTasks < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :large

    def call
      list_from(scope, view_all_path: admin_projects_path)
    end

    private

    def scope
      Task.includes(:project).where.not(status: :done).where(due_date: Date.current..).order(:due_date)
    end

    def row(task)
      Bali::Widget::Row.new(
        title: task.title,
        subtitle: subtitle(task.project.name, task.priority.humanize),
        href: admin_project_path(task.project)
      )
    end
  end
end
