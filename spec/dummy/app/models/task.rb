# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to :project
  has_many :outgoing_dependencies, class_name: 'TaskDependency',
                                   foreign_key: :predecessor_id,
                                   inverse_of: :predecessor, dependent: :destroy
  has_many :incoming_dependencies, class_name: 'TaskDependency',
                                   foreign_key: :successor_id,
                                   inverse_of: :successor, dependent: :destroy

  validates :title, presence: true

  enum :status, { backlog: 0, todo: 1, in_progress: 2, done: 3 }
  enum :priority, { low: 0, medium: 1, high: 2 }

  scope :positioned, -> { order(:position) }

  STATUSES = statuses.keys.freeze
  STATUS_COLORS = { "backlog" => :ghost, "todo" => :info, "in_progress" => :warning, "done" => :success }.freeze
  PRIORITY_COLORS = { "low" => :ghost, "medium" => :warning, "high" => :error }.freeze
end
