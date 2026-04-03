# frozen_string_literal: true

class Studio < ApplicationRecord
  enum :status, { active: 0, inactive: 1, pending: 2 }

  COUNTRIES = %w[USA UK France Germany Japan India Australia Canada].freeze
  SIZES = %w[small medium large enterprise].freeze

  validates :name, presence: true

  scope :by_country, ->(country) { where(country: country) if country.present? }
  scope :by_size, ->(size) { where(size: size) if size.present? }

  def self.filter_options
    [
      { attribute: :country, collection: COUNTRIES.map { |c| [ c, c ] }, blank: "All Countries", label: "Country" },
      { attribute: :status, collection: statuses.map { |s, v| [ s.humanize, v ] }, label: "Status", type: :toggle_group, predicate: :in },
      { attribute: :size, collection: SIZES.map { |s| [ s.humanize, s ] }, blank: "All Sizes", label: "Size" },
      { attribute: :created_at, type: :date_range, label: "Created between" }
    ]
  end

  def status_color
    case status
    when "active" then :success
    when "inactive" then :error
    else :warning
    end
  end
end
