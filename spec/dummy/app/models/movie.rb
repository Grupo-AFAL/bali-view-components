# frozen_string_literal: true

class Movie < ApplicationRecord
  belongs_to :tenant
  # rubocop: disable Rails/HasManyOrHasOneDependent
  has_many :characters
  # rubocop: enable Rails/HasManyOrHasOneDependent

  accepts_nested_attributes_for :characters, allow_destroy: true

  enum :status, { draft: 0, done: 1 }

  attribute :indie, :boolean
  attribute :synopsis
  attribute :duration, default: -> { "#{Date.current} 00:00:00" }
  attribute :release_date
  attribute :budget
  attribute :contact_email
  attribute :cover_photo
  attribute :rating
  attribute :available_region
  attribute :website_url
  attribute :time_zone

  scope :active, -> { where(status: 0) }
end
