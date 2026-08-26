# frozen_string_literal: true

module DemoWidgets
  # `small` renders no rows at all — just the count and a link to the whole
  # tile, so `#call` still builds the full scope through `list_from`: the size
  # decides how much of it the card shows, not what this method loads.
  class OverdueTasks < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :small

    def call
      list_from(scope, view_all_path: admin_projects_path)
    end

    # `small` renders the fact alone, so this is where the trend has to earn its
    # place in four to six characters — an arrow and a delta, nothing else.

    private

    def scope
      Task.includes(:project).where.not(status: :done).where(due_date: ...Date.current).order(:due_date)
    end

    def row(task)
      Bali::Widget::Row.new(title: task.title, href: admin_project_path(task.project))
    end
  end
end
