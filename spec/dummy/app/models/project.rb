# frozen_string_literal: true

class Project < ApplicationRecord
  has_many :tasks, dependent: :destroy

  validates :name, presence: true

  def tasks_by_status
    tasks.order(:position).group_by(&:status)
  end
end
