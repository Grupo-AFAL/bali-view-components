# frozen_string_literal: true

class Character < ApplicationRecord
  belongs_to :movie

  validates :name, presence: true

  attribute :birth_month, MonthValue.new

  default_scope { order(:position) }
end
