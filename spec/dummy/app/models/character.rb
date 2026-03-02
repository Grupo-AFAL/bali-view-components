# frozen_string_literal: true

class Character < ApplicationRecord
  belongs_to :movie

  validates :name, presence: true

  attribute :birth_month, MonthValue.new

  before_create :set_position

  default_scope { order(:position) }

  private

  def set_position
    self.position = movie.characters.maximum(:position).to_i + 1
  end
end
