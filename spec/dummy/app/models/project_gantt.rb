# frozen_string_literal: true

# Reference implementation of the Bali::Gantt data contract for a host app
# (#704/#705): turns a Project's tasks into the document the component and the
# React island consume. Groups come from each task's phase (rolled-up dates
# give the group its own bar), items carry status/milestone/percent_complete,
# tasks without dates are passed through so the "No dates" section stays
# honest, and `dependencies`/`critical_ids` feed the island's arrows and
# critical path.
#
# The "CPM" here is deliberately naive (longest total-duration dependency
# chain): the contract only requires that the SERVER computes the schedule and
# the critical path and returns the complete document — see
# Admin::Projects::SchedulesController for the mutation side.
class ProjectGantt
  # Task status → daisyUI color variable for the gantt catalog (nil = neutral).
  # Mirrors Task::STATUS_COLORS, which paints the same states on the Kanban.
  STATUS_VARS = {
    "backlog" => nil,
    "todo" => "--color-info",
    "in_progress" => "--color-warning",
    "done" => "--color-success"
  }.freeze

  # Task priority → oklch hue for the island catalog (nil = neutral, no flag).
  PRIORITY_HUES = { "high" => 25, "medium" => 45, "low" => nil }.freeze

  def initialize(project)
    @project = project
  end

  def to_h
    { groups: groups, items: items, dependencies: dependencies, critical_ids: critical_ids }
  end

  # Status catalog for Bali::Gantt::Component (legend labels + colors).
  def statuses
    Task.statuses.keys.map do |status|
      { value: status, label: status.humanize, color: STATUS_VARS[status] }
    end
  end

  # Catalogs prop of the island (#705, D11): ordered arrays the host builds
  # from its enums + i18n.
  def catalogs
    {
      statuses: statuses,
      priorities: Task.priorities.keys.map do |priority|
        { value: priority, label: priority.humanize, hue: PRIORITY_HUES[priority] }
      end
    }
  end

  private

  def tasks
    @tasks ||= @project.tasks.positioned.to_a
  end

  def task_dependencies
    @task_dependencies ||= TaskDependency
                           .where(predecessor_id: tasks.map(&:id))
                           .order(:id).to_a
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
        status: task.status, priority: task.priority, milestone: task.milestone?,
        percent_complete: task.percent_complete }
    end
  end

  def dependencies
    task_dependencies.map do |dep|
      { id: dep.id, predecessor_id: dep.predecessor_id, successor_id: dep.successor_id,
        dependency_type: "finish_to_start", lag_days: dep.lag_days }
    end
  end

  # Naive critical path: the dependency chain with the largest total duration.
  # Without dependencies there is no path to speak of — an empty array, not
  # "every task is critical".
  def critical_ids
    return [] if task_dependencies.empty?

    duration = tasks.index_by(&:id).transform_values do |task|
      task.start_date && task.due_date ? (task.due_date - task.start_date).to_i + 1 : 0
    end
    successors = task_dependencies.group_by(&:predecessor_id)

    # longest[id] = [total_duration, path_ids] starting at id, memoized.
    longest = {}
    walk = lambda do |id|
      longest[id] ||= begin
        best = [ 0, [] ]
        (successors[id] || []).each do |dep|
          candidate = walk.call(dep.successor_id)
          best = candidate if candidate[0] > best[0]
        end
        [ duration.fetch(id, 0) + best[0], [ id ] + best[1] ]
      end
    end

    entry_ids = duration.keys
    entry_ids.map { |id| walk.call(id) }.max_by(&:first)&.last || []
  end
end
