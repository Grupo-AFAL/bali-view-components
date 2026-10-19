# frozen_string_literal: true

# The demo's «Te toca»: every open task. The dummy has one user and tasks have no assignee, so
# what is pending is everything not done.
class TaskInboxProvider
  include Bali::Inbox::Provider

  def kind = :task

  def icon = "list-checks"

  def pending_for(_user) = Task.where.not(status: :done).includes(:project)

  def build_item(task, user:)
    item task, title: task.title, subtitle: task.project.name, due_at: task.due_date,
               href: admin_project_path(task.project)
  end
end
