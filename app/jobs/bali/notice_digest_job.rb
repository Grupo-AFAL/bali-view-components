# frozen_string_literal: true

module Bali
  # #1512 — the hourly digest. The host schedules it (Solid Queue's `config/recurring.yml`):
  #
  #   notice_digest:
  #     class: Bali::NoticeDigestJob
  #     schedule: every hour
  class NoticeDigestJob < ApplicationJob
    STALE_AFTER = 1.hour

    def perform
      NoticeDelivery.reclaim_stale!(STALE_AFTER.ago)
      deliveries = NoticeDelivery.where(id: NoticeDelivery.claim_digest!).includes(notice: :recipient)

      seen, unseen = deliveries.partition { |delivery| delivery.notice.read_at }
      NoticeDelivery.where(id: seen.map(&:id)).update_all(status: "skipped", updated_at: Time.current)

      unseen.group_by { |delivery| delivery.notice.recipient }.each do |recipient, rows|
        send_digest(recipient, rows)
      end
    end

    private

    # Each recipient on their own: one address that fails does not hold back anyone else's.
    def send_digest(recipient, rows)
      NoticeDigestMailer.digest(recipient, rows.map(&:notice)).deliver_now
      NoticeDelivery.where(id: rows.map(&:id))
                    .update_all([ "status = 'delivered', delivered_at = ?, updated_at = ?, attempts = attempts + 1",
                                  Time.current, Time.current ])
    rescue StandardError => error
      NoticeDelivery.record_failure!(rows.map(&:id), error, attempts: NoticeDeliveryJob::ATTEMPTS)
    end
  end
end
