# frozen_string_literal: true

class Movie < ApplicationRecord
  belongs_to :tenant
  has_many :characters

  enum status: { draft: 0, done: 1 }

  attribute :indie, :boolean
  attribute :synopsis
  attribute :duration, default: -> { "#{Date.current} 00:00:00" }
  attribute :release_date
  attribute :budget
  attribute :contact_email
  attribute :cover_photo
  attribute :rating

  scope :active, -> { where(status: 0) }
end
