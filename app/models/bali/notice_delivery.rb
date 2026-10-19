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

    # The pending digest rows, taken by this run alone. On Postgres a run that overlaps skips the
    # rows already locked; SQLite has no row locks (Arel drops the clause) and serializes writes,
    # which makes the claim exclusive there too.
    def self.claim_digest!
      transaction do
        ids = pending.digest.order(:id).lock("FOR UPDATE SKIP LOCKED").pluck(:id)
        where(id: ids).update_all(status: "sending", updated_at: Time.current)
        ids
      end
    end

    # A run killed mid-send leaves its rows in `sending`. Back to `pending`, so the next run sends
    # them: a digest can go out twice this way, but none is lost.
    def self.reclaim_stale!(before)
      where(status: "sending").where(updated_at: ...before).update_all(status: "pending", updated_at: Time.current)
    end

    # One more attempt, `failed` at the last.
    def self.record_failure!(ids, error, attempts:)
      where(id: ids).find_each do |delivery|
        failed = delivery.attempts + 1 >= attempts
        delivery.update!(attempts: delivery.attempts + 1, status: failed ? "failed" : "pending",
                         failed_at: (Time.current if failed),
                         failure_reason: "#{error.class}: #{error.message}".truncate(255))
      end
    end
  end
end
