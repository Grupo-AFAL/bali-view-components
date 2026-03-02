# frozen_string_literal: true

class Movie < ApplicationRecord
  belongs_to :tenant
  belongs_to :studio, class_name: "Tenant", foreign_key: "tenant_id", optional: true
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

  scope :in_production, -> { draft }

  def status_color
    done? ? :success : :warning
  end
  scope :by_genre_count, -> { group(:genre).count }
  scope :by_status_count, -> { group(:status).count.transform_keys(&:humanize) }
  scope :budgeted, -> { where("budget > 0") }

  def self.average_rating
    where.not(rating: nil).average(:rating)&.round(1) || 0
  end

  def self.ratings_by_genre
    where.not(rating: nil).group(:genre).average(:rating).transform_values { |v| v.round(1) }
  end

  def self.budget_by_genre
    where.not(budget: nil).group(:genre).sum(:budget)
  end

  def self.budget_by_status
    where.not(budget: nil)
      .group(:status)
      .sum(:budget)
      .transform_keys(&:humanize)
  end

  def reorder_characters(ordered_ids)
    transaction do
      ordered_ids.each_with_index do |id, index|
        characters.where(id: id).update_all(position: index)
      end
    end
  end
end
