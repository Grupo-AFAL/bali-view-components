# frozen_string_literal: true

class Character < ApplicationRecord
  belongs_to :movie

  attribute :birth_month, MonthValue.new
end
