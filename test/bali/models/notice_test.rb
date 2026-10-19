# frozen_string_literal: true

require "test_helper"

# #1512 — a notice is a stored "what happened" for one recipient. Its kind decides whether it
# goes out by email and whether it announces an inbox item.
class BaliNoticeTest < ActiveSupport::TestCase
  def setup
    @kinds = Bali.notice_kinds
    @deliver_if = Bali.notices_deliver_if
    Bali.notice_kinds = {
      movie_assigned: { email: :immediate, announces: :task },
      movie_digest: { email: :digest },
      movie_released: {}
    }
    @ana = User.create!(name: "Ana")
    @luis = User.create!(name: "Luis")
    @movie = Tenant.create!(name: "Studio").movies.create!(name: "Alien", status: 0)
  end

  def teardown
    Bali.notice_kinds = @kinds
    Bali.notices_deliver_if = @deliver_if
  end

  def notice(kind, recipient: @ana, **attributes)
    Bali::Notice.create!(recipient: recipient, notifiable: @movie, kind: kind, message: "Hello", **attributes)
  end

  def test_a_notice_of_an_unregistered_kind_is_invalid
    notice = Bali::Notice.new(recipient: @ana, kind: "movie_vanished", message: "Hello")

    refute notice.valid?
    assert notice.errors.added?(:kind, :inclusion, value: "movie_vanished")
  end

  def test_an_email_mode_outside_the_three_raises_naming_the_kind
    Bali.notice_kinds = { movie_assigned: { email: :weekly } }

    error = assert_raises(ArgumentError) { Bali::Notice.kinds }
    assert_match "movie_assigned", error.message
  end

  # Otherwise every immediate notice fails five times, a NoMethodError at a time, before the log
  # says why.
  def test_an_immediate_kind_without_a_mailer_raises_naming_the_setting
    mailer = Bali.notices_mailer
    Bali.notices_mailer = nil

    error = assert_raises(ArgumentError) { Bali::Notice.kinds }
    assert_match "Bali.notices_mailer", error.message
    assert_match "movie_assigned", error.message
  ensure
    Bali.notices_mailer = mailer
  end

  def test_listed_leaves_out_the_kinds_that_announce
    released = notice(:movie_released)
    notice(:movie_assigned)

    assert_equal [ released ], Bali::Notice.listed.to_a
    assert_equal %w[movie_assigned], Bali::Notice.announcing_kinds
  end

  def test_an_immediate_kind_writes_a_pending_immediate_delivery
    delivery = notice(:movie_assigned).delivery

    assert_equal %w[immediate pending], [ delivery&.mode, delivery&.status ]
  end

  # Written after commit instead, the notice would survive a delivery that failed to be written.
  def test_a_delivery_that_cannot_be_written_takes_the_notice_with_it
    Bali.notices_deliver_if = ->(_notice) { raise "delivery log unavailable" }

    assert_raises(RuntimeError) { notice(:movie_assigned) }
    assert_equal 0, Bali::Notice.count
  end

  def test_a_digest_kind_writes_a_pending_digest_delivery
    assert_equal "digest", notice(:movie_digest).delivery&.mode
  end

  def test_a_kind_without_email_writes_no_delivery
    assert_nil notice(:movie_released).delivery
  end

  def test_notices_deliver_if_false_writes_no_delivery
    Bali.notices_deliver_if = ->(_notice) { false }

    assert_nil notice(:movie_assigned).delivery
  end

  def test_mark_all_read_reads_every_unread_notice_of_that_recipient_only
    mine = [ notice(:movie_released), notice(:movie_assigned) ]
    theirs = notice(:movie_released, recipient: @luis)

    assert_equal 2, Bali::Notice.mark_all_read!(@ana)
    assert mine.map(&:reload).none?(&:unread?)
    assert theirs.reload.unread?
  end

  def test_recent_orders_newest_first
    older = notice(:movie_released, created_at: 2.days.ago)
    newer = notice(:movie_released)

    assert_equal [ newer, older ], Bali::Notice.addressed_to(@ana).recent.to_a
  end
end
