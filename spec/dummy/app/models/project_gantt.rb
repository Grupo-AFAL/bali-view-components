# frozen_string_literal: true

# Reference implementation of the Bali::Gantt data contract for a host app
# (#704): turns a Project's tasks into the document the component consumes.
# Groups come from each task's phase (rolled-up dates give the group its own
# bar), items carry status/milestone/percent_complete, and tasks without dates
# are passed through so the component's "No dates" section stays honest.
class ProjectGantt
  # Task status → daisyUI color variable for the gantt catalog (nil = neutral).
  # Mirrors Task::STATUS_COLORS, which paints the same states on the Kanban.
  STATUS_VARS = {
    "backlog" => nil,
    "todo" => "--color-info",
    "in_progress" => "--color-warning",
    "done" => "--color-success"
  }.freeze

  def initialize(project)
    @project = project
  end

  def to_h
    { groups: groups, items: items }
  end

  # Status catalog for Bali::Gantt::Component (legend labels + colors).
  def statuses
    Task.statuses.keys.map do |status|
      { value: status, label: status.humanize, color: STATUS_VARS[status] }
    end
  end

  private

  def tasks
    @tasks ||= @project.tasks.positioned.to_a
  end

  # Phases in order of first appearance, each with its rolled-up date range.
  def groups
    tasks.map(&:phase).compact.uniq.map do |phase|
      phase_tasks = tasks.select { |t| t.phase == phase && t.start_date }
      { id: phase.parameterize, name: phase,
        starts_on: phase_tasks.filter_map(&:start_date).min&.iso8601,
        ends_on: phase_tasks.filter_map(&:due_date).max&.iso8601 }
    end
  end

  def items
    tasks.map do |task|
      { id: task.id, group_id: task.phase&.parameterize, name: task.title,
        starts_on: task.start_date&.iso8601, ends_on: task.due_date&.iso8601,
        status: task.status, milestone: task.milestone?,
        percent_complete: task.percent_complete }
    end
  end
end
