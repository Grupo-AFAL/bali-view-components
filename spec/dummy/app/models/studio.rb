# frozen_string_literal: true

class Studio < ApplicationRecord
  enum :status, { active: 0, inactive: 1, pending: 2 }

  COUNTRIES = %w[USA UK France Germany Japan India Australia Canada].freeze
  SIZES = %w[small medium large enterprise].freeze

  validates :name, presence: true

  scope :by_country, ->(country) { where(country: country) if country.present? }
  scope :by_size, ->(size) { where(size: size) if size.present? }
end
