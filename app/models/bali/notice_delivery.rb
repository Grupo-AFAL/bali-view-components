# frozen_string_literal: true

module Bali
  # #1512 — the delivery log: one row per notice that goes out by email.
  class NoticeDelivery < ApplicationRecord
    STATUSES = %w[pending sending delivered failed skipped].freeze
    MODES = %w[immediate digest].freeze

    belongs_to :notice, class_name: "Bali::Notice"

    validates :status, inclusion: { in: STATUSES }
    validates :mode, inclusion: { in: MODES }

    scope :pending, -> { where(status: "pending") }
    scope :digest, -> { where(mode: "digest") }
  end
end
