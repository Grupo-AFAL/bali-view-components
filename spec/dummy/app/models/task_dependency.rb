# frozen_string_literal: true

# A finish-to-start dependency between two tasks of the same project. Feeds
# the Gantt island's arrows and the reference schedule endpoint (#705). The
# validations mirror what a real host must enforce (afal-apps does the same in
# its TaskScheduler): no self-links, no duplicates, no cycles, same project —
# each rejected with 422 so the island can roll back its optimistic edge.
class TaskDependency < ApplicationRecord
  belongs_to :predecessor, class_name: 'Task'
  belongs_to :successor, class_name: 'Task'

  validates :successor_id, uniqueness: { scope: :predecessor_id, message: 'dependency already exists' }
  validate :not_self_referential
  validate :same_project
  validate :no_cycles

  private

  def not_self_referential
    return unless predecessor_id == successor_id

    errors.add(:base, 'a task cannot depend on itself')
  end

  def same_project
    return if predecessor.nil? || successor.nil?
    return if predecessor.project_id == successor.project_id

    errors.add(:base, 'both tasks must belong to the same project')
  end

  # DFS from the successor: if the predecessor is reachable, this edge would
  # close a cycle.
  def no_cycles
    return if predecessor_id.nil? || successor_id.nil? || predecessor_id == successor_id

    reachable = [ successor_id ]
    seen = Set.new(reachable)
    until reachable.empty?
      next_ids = TaskDependency.where(predecessor_id: reachable).pluck(:successor_id) - seen.to_a
      errors.add(:base, 'this dependency would create a cycle') and return if next_ids.include?(predecessor_id)

      seen.merge(next_ids)
      reachable = next_ids
    end
  end
end
