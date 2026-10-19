# frozen_string_literal: true

module Bali
  # #1512 — the hourly digest, and the hourly sweep of immediate deliveries whose job never ran.
  # The host schedules it whenever any kind has `email:` (Solid Queue's `config/recurring.yml`):
  #
  #   notice_digest:
  #     class: Bali::NoticeDigestJob
  #     schedule: every hour
  class NoticeDigestJob < ApplicationJob
    STALE_AFTER = 1.hour

    def perform
      resend_stranded
      NoticeDelivery.reclaim_stale!(STALE_AFTER.ago)
      deliveries = NoticeDelivery.where(id: NoticeDelivery.claim_digest!).includes(notice: :recipient)

      seen, unseen = deliveries.partition { |delivery| delivery.notice.read_at }
      NoticeDelivery.where(id: seen.map(&:id)).update_all(status: "skipped", updated_at: Time.current)

      unseen.group_by { |delivery| delivery.notice.recipient }.each do |recipient, rows|
        send_digest(recipient, rows)
      end
    end

    private

    # A worker of the previous deploy can take a delivery job whose class it does not have yet, and
    # fail it: the row stays `pending` with no job behind it. Enqueued again, its job sends it or —
    # if it was only slow in the queue and went out meanwhile — finds it delivered and does nothing.
    def resend_stranded
      NoticeDelivery.pending.where(mode: "immediate").where(updated_at: ...STALE_AFTER.ago)
                    .find_each { |delivery| NoticeDeliveryJob.enqueue(delivery) }
    end

    # Each recipient on their own: one address that fails does not hold back anyone else's.
    def send_digest(recipient, rows)
      NoticeDigestMailer.digest(recipient, rows.map(&:notice)).deliver_now
      NoticeDelivery.where(id: rows.map(&:id))
                    .update_all([ "status = 'delivered', delivered_at = ?, updated_at = ?, attempts = attempts + 1",
                                  Time.current, Time.current ])
    rescue StandardError => error
      failed = NoticeDelivery.record_failure!(rows.map(&:id), error, attempts: NoticeDeliveryJob::ATTEMPTS)
      Rails.error.report(error, handled: false, context: { notice_delivery_ids: failed }) if failed.any?
    end
  end
end
