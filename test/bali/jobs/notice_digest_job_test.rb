# frozen_string_literal: true

require "test_helper"

# #1512 — the hourly digest: every :digest notice waiting in the delivery log, one email per
# recipient.
class BaliNoticeDigestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  def setup
    # ActiveJob::TestCase does not empty it between tests the way ActionMailer::TestCase does.
    ActionMailer::Base.deliveries.clear
    @kinds = Bali.notice_kinds
    Bali.notice_kinds = { movie_digest: { email: :digest }, movie_released: {} }
    @ana = User.create!(name: "Ana")
    @luis = User.create!(name: "Luis")
    @movie = Tenant.create!(name: "Studio").movies.create!(name: "Alien", status: 0)
  end

  def teardown
    Bali.notice_kinds = @kinds
  end

  def notify(recipient = @ana)
    @movie.notify(recipient: recipient, kind: :movie_digest, message: "Alien needs review",
                  action_url: "/movies")
  end

  # Run one after the other; overlapping runs rest on the row lock, which SQLite does not have.
  def test_a_second_run_finds_nothing_the_first_claimed
    notify
    notify(@luis)

    first = Bali::NoticeDelivery.claim_digest!

    assert_equal 2, first.size
    assert_equal [], Bali::NoticeDelivery.claim_digest!
  end

  def test_groups_by_recipient_one_email_each
    2.times { notify }
    notify(@luis)

    assert_emails(2) { Bali::NoticeDigestJob.perform_now }
    assert_equal [ [ "ana@example.com" ], [ "luis@example.com" ] ],
                 ActionMailer::Base.deliveries.map(&:to).sort
    assert_equal %w[delivered], Bali::NoticeDelivery.distinct.pluck(:status)
  end

  def test_a_notice_read_before_the_run_is_skipped_and_a_recipient_left_with_nothing_gets_no_email
    notify.mark_read!

    assert_no_emails { Bali::NoticeDigestJob.perform_now }
    assert_equal %w[skipped], Bali::NoticeDelivery.pluck(:status)
  end

  def test_a_row_stuck_in_sending_for_over_an_hour_returns_to_pending_and_goes_out
    delivery = notify.delivery
    delivery.update_columns(status: "sending", updated_at: 61.minutes.ago)

    assert_emails(1) { Bali::NoticeDigestJob.perform_now }
    assert_equal "delivered", delivery.reload.status
  end

  def test_a_row_sending_for_less_than_an_hour_is_left_to_its_run
    delivery = notify.delivery
    delivery.update_columns(status: "sending", updated_at: 10.minutes.ago)

    assert_no_emails { Bali::NoticeDigestJob.perform_now }
    assert_equal "sending", delivery.reload.status
  end

  def test_a_failed_send_puts_the_rows_back_to_pending_with_one_more_attempt_failed_at_the_fifth
    delivery = notify(User.create!(name: "")).delivery

    Bali::NoticeDigestJob.perform_now
    assert_equal [ "pending", 1 ], [ delivery.reload.status, delivery.attempts ]

    4.times { Bali::NoticeDigestJob.perform_now }

    assert_equal [ "failed", 5 ], [ delivery.reload.status, delivery.attempts ]
    assert_match "Bali::NoticeDigestMailer::MissingRecipientEmail", delivery.failure_reason
  end

  def test_the_fifth_failed_digest_is_reported_to_the_error_reporter
    delivery = notify(User.create!(name: "")).delivery
    4.times { Bali::NoticeDigestJob.perform_now }

    assert_error_reported(Bali::NoticeDigestMailer::MissingRecipientEmail) { Bali::NoticeDigestJob.perform_now }
    assert_equal "failed", delivery.reload.status
  end

  # An immediate delivery whose job never ran — a worker of the previous deploy took it and did
  # not know the class — waits for nothing. The hourly run sends it again.
  def test_an_immediate_delivery_stuck_pending_for_over_an_hour_is_enqueued_again
    Bali.notice_kinds = Bali.notice_kinds.merge(movie_assigned: { email: :immediate })
    stuck = @movie.notify(recipient: @ana, kind: :movie_assigned, message: "Review Alien").delivery
    stuck.update_columns(updated_at: 61.minutes.ago)
    clear_enqueued_jobs

    assert_enqueued_with(job: Bali::NoticeDeliveryJob, args: [ stuck ]) { Bali::NoticeDigestJob.perform_now }
  end

  def test_an_immediate_delivery_pending_for_less_than_an_hour_is_left_to_its_job
    Bali.notice_kinds = Bali.notice_kinds.merge(movie_assigned: { email: :immediate })
    @movie.notify(recipient: @ana, kind: :movie_assigned, message: "Review Alien").delivery.update_columns(updated_at: 10.minutes.ago)
    clear_enqueued_jobs

    assert_no_enqueued_jobs(only: Bali::NoticeDeliveryJob) { Bali::NoticeDigestJob.perform_now }
  end

  def test_one_recipient_failing_does_not_hold_back_the_others
    notify(User.create!(name: ""))
    notify

    assert_emails(1) { Bali::NoticeDigestJob.perform_now }
  end
end
