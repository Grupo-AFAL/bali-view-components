# frozen_string_literal: true

module Bali
  # #1512 — sends one :immediate notice through the host's mailer (`Bali.notices_mailer`) and
  # writes what happened in its delivery row.
  class NoticeDeliveryJob < ApplicationJob
    ATTEMPTS = 5

    # Past the last attempt the error is recorded in the row and reported to Rails.error, which is
    # what an error tracker listens to: swallowed into the row alone, a lost email is silent.
    retry_on StandardError, wait: :polynomially_longer, attempts: ATTEMPTS do |job, error|
      delivery = job.arguments.first
      delivery.update!(status: "failed", failed_at: Time.current,
                       failure_reason: "#{error.class}: #{error.message}".truncate(255))
      Rails.error.report(error, handled: false, context: { notice_delivery_id: delivery.id })
    end

    # The notice, and its delivery with it, may be gone by the time the job runs.
    discard_on ActiveJob::DeserializationError

    def self.enqueue(delivery)
      queue = Bali::Notice.kind(delivery.notice.kind)&.queue || :default
      set(queue: queue).perform_later(delivery)
    end

    def perform(delivery)
      return unless delivery.status == "pending"

      delivery.increment!(:attempts)
      Bali.notices_mailer.constantize.notify(delivery.notice).deliver_now
      delivery.update!(status: "delivered", delivered_at: Time.current)
    end
  end
end
