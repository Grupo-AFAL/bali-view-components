# frozen_string_literal: true

module DemoWidgets
  # THE CHECK LADDER, not yet known. NIL is a third state, not a failure: no
  # movie carries a rating, so the question has no answer rather than a bad one.
  # The card draws the muted icon, and `count` is 0 — which is what stops a
  # pending check from claiming a pass.
  class RatingsAudit < Bali::Widget::CheckBase
    default_size :small

    check do |c|
      c.value { rated.zero? ? nil : rated == Movie.count }
      c.pass { "All #{Movie.count} rated" }
      c.fail { "#{Movie.count - rated} unrated" }
    end

    private

    def rated = @rated ||= Movie.where.not(rating: nil).count
  end
end
