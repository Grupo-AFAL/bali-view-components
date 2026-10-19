# frozen_string_literal: true

module Bali
  # #1512 — sends one :immediate notice through the host's mailer (`Bali.notices_mailer`) and
  # writes what happened in its delivery row.
  class NoticeDeliveryJob < ApplicationJob
    ATTEMPTS = 5

    # Past the last attempt the error is recorded, not raised: the row is the record of it.
    retry_on StandardError, wait: :polynomially_longer, attempts: ATTEMPTS do |job, error|
      job.arguments.first.update!(status: "failed", failed_at: Time.current,
                                  failure_reason: "#{error.class}: #{error.message}".truncate(255))
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
