# frozen_string_literal: true

class Workout < ApplicationRecord
  attribute :name
  attribute :workout_start_at, TimeValue.new
  attribute :workout_end_at, TimeValue.new

  validates :name, presence: true, if: :validate_name

  attr_accessor :validate_name
end
