# frozen_string_literal: true

require "test_helper"

# #1512 — `notify` is how a host model writes a notice about itself. The dummy's Movie adopts the
# concern.
class BaliNotifiableTest < ActiveSupport::TestCase
  def setup
    @kinds = Bali.notice_kinds
    Bali.notice_kinds = { movie_assigned: { email: :immediate }, movie_released: {} }
    @ana = User.create!(name: "Ana")
    @movie = Tenant.create!(name: "Studio").movies.create!(name: "Alien", status: 0)
  end

  def teardown
    Bali.notice_kinds = @kinds
  end

  def test_notify_writes_a_notice_about_the_record
    notice = @movie.notify(recipient: @ana, kind: :movie_released, message: "Alien is out",
                           actor: @ana, action_url: "/movies/1")

    assert_equal [ @movie, @ana, @ana, "movie_released", "Alien is out", "/movies/1" ],
                 [ notice.notifiable, notice.recipient, notice.actor, notice.kind, notice.message,
                   notice.action_url ]
  end

  def test_notify_with_a_blank_recipient_creates_nothing
    assert_no_difference -> { Bali::Notice.count } do
      assert_nil @movie.notify(recipient: nil, kind: :movie_released, message: "Alien is out")
    end
  end

  def test_notify_with_a_used_idempotency_key_returns_the_existing_notice
    first = @movie.notify(recipient: @ana, kind: :movie_released, message: "Alien is out",
                          idempotency_key: "event-7:ana")

    assert_no_difference -> { Bali::Notice.count } do
      again = assert_nothing_raised do
        @movie.notify(recipient: @ana, kind: :movie_released, message: "Alien is out",
                      idempotency_key: "event-7:ana")
      end
      assert_equal first, again
    end
  end

  def test_destroying_the_notifiable_destroys_its_notices_and_their_deliveries
    @movie.notify(recipient: @ana, kind: :movie_assigned, message: "Review Alien")

    assert_difference [ -> { Bali::Notice.count }, -> { Bali::NoticeDelivery.count } ], -1 do
      @movie.destroy!
    end
  end
end
