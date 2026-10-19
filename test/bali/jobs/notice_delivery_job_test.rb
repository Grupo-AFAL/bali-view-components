# frozen_string_literal: true

require "test_helper"

# #1512 — an :immediate notice goes out through the host's mailer, and the delivery log says
# whether it did.
class BaliNoticeDeliveryJobTest < ActiveJob::TestCase
  # A host mailer whose SMTP server keeps refusing.
  class RefusingMailer < ApplicationMailer
    def notify(_notice) = raise("421 try later")
  end

  include ActionMailer::TestHelper

  def setup
    # ActiveJob::TestCase does not empty it between tests the way ActionMailer::TestCase does.
    ActionMailer::Base.deliveries.clear
    @kinds = Bali.notice_kinds
    @mailer = Bali.notices_mailer
    Bali.notice_kinds = { movie_assigned: { email: :immediate },
                          movie_welcome: { email: :immediate, queue: :low } }
    Bali.notices_mailer = "NoticeMailer"
    @ana = User.create!(name: "Ana")
    @movie = Tenant.create!(name: "Studio").movies.create!(name: "Alien", status: 0)
  end

  def teardown
    Bali.notice_kinds = @kinds
    Bali.notices_mailer = @mailer
  end

  def notify(kind = :movie_assigned, recipient: @ana)
    @movie.notify(recipient: recipient, kind: kind, message: "Review Alien", action_url: "/movies")
  end

  def test_delivers_once_and_stamps_delivered_at
    notice = nil
    assert_emails(1) { notice = perform_enqueued_jobs { notify } }

    assert_equal [ "ana@example.com" ], ActionMailer::Base.deliveries.last.to
    assert_equal [ "delivered", 1 ], [ notice.delivery.reload.status, notice.delivery.attempts ]
    assert notice.delivery.delivered_at
  end

  def test_a_delivered_row_is_not_sent_again
    notice = perform_enqueued_jobs { notify }

    assert_no_emails { Bali::NoticeDeliveryJob.perform_now(notice.delivery.reload) }
  end

  def test_each_failure_counts_an_attempt_and_the_fifth_leaves_it_failed_with_the_reason
    Bali.notices_mailer = RefusingMailer.name

    delivery = perform_enqueued_jobs { notify }.delivery.reload

    assert_equal [ "failed", 5 ], [ delivery.status, delivery.attempts ]
    assert_equal "RuntimeError: 421 try later", delivery.failure_reason
    assert delivery.failed_at
  end

  def test_a_recipient_with_no_email_ends_failed_and_the_notice_survives
    nobody = User.create!(name: "")

    notice = perform_enqueued_jobs { notify(recipient: nobody) }

    assert_equal "failed", notice.delivery.reload.status
    assert Bali::Notice.exists?(notice.id)
  end

  def test_an_immediate_kind_with_a_queue_is_enqueued_on_it
    assert_enqueued_with(job: Bali::NoticeDeliveryJob, queue: "low") { notify(:movie_welcome) }
  end
end
