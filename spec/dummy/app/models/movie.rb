# frozen_string_literal: true

class Movie < ApplicationRecord
  belongs_to :studio, class_name: "Tenant", foreign_key: "tenant_id"
  alias_method :tenant, :studio

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

  scope :budgeted, -> { where(budget: 1..) }
  scope :indie, -> { where(indie: true) }
  scope :top_rated, ->(limit: 5) { includes(:studio).order(rating: :desc).limit(limit) }

  def self.by_genre_count = group(:genre).count
  def self.by_status_count = group(:status).count.transform_keys(&:humanize)

  def self.average_rating
    where.not(rating: nil).average(:rating)&.round(1) || 0
  end

  def self.completion_rate
    total = count
    return 0 if total.zero?

    (done.count * 100.0 / total).round
  end

  def self.ratings_by_genre
    where.not(rating: nil).group(:genre).average(:rating).transform_values { |v| v.round(1) }
  end

  def self.budget_by_genre
    budgeted.group(:genre).sum(:budget)
  end

  def self.budget_by_status
    budgeted
      .group(:status)
      .sum(:budget)
      .transform_keys(&:humanize)
  end

  def status_color
    done? ? :success : :warning
  end

  def reorder_characters(ordered_ids)
    transaction do
      ordered_ids.each_with_index do |id, index|
        characters.where(id: id).update_all(position: index)
      end
    end
  end
end
