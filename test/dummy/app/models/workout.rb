# frozen_string_literal: true

class Workout < ApplicationRecord
  attribute :name
  attribute :workout_start_at, TimeValue.new
  attribute :workout_end_at, TimeValue.new

  validates :name, presence: true, if: :validate_name
  validates :files, presence: true, if: :validate_files

  attr_accessor :validate_name, :validate_files

  has_many_attached :files
end
