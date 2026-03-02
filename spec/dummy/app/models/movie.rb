# frozen_string_literal: true

class Movie < ApplicationRecord
  belongs_to :tenant
  has_many :characters, dependent: :destroy

  # Active Storage attachment for DirectUpload demo
  has_one_attached :poster

  accepts_nested_attributes_for :characters, allow_destroy: true

  GENRES = %w[Action Adventure Animation Comedy Crime Documentary Drama Fantasy Horror Musical Romance Sci-Fi Thriller Western].freeze

  enum :status, { draft: 0, done: 1 }

  # Virtual attributes (not persisted)
  attribute :duration, default: -> { "#{Date.current} 00:00:00" }
  attribute :cover_photo
  attribute :available_region

  scope :active, -> { draft }
  scope :by_genre_count, -> { group(:genre).count }
  scope :by_status_count, -> { group(:status).count.transform_keys(&:humanize) }

  def self.average_rating
    where.not(rating: nil).average(:rating)&.round(1) || 0
  end
end
