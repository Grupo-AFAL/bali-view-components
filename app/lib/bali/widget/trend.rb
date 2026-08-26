# frozen_string_literal: true

module Bali
  module Widget
    # How the headline number is moving. The comparison, not the conclusion.
    #
    # `positive_when` is the field that earns this class its existence. "Up" is
    # NOT universally good — overdue tasks up 12% and revenue up 12% are opposite
    # news, and `direction` alone cannot tell them apart. A card colouring from
    # `direction` would paint half the dashboard's trends the wrong way and read
    # as confident while doing it, which is worse than showing no trend at all.
    #
    # So the widget declares what counts as good for ITS metric and the card asks
    # `good?`, never `direction`.
    Trend = Data.define(:delta, :direction, :period, :positive_when) do
      # `direction` is derived from the sign by default, because a widget that
      # has computed a delta has already said which way it went — making it say
      # so twice is an invitation for the two to disagree. Still overridable for
      # the case where the delta is not the thing that moved.
      def initialize(delta:, direction: nil, period: nil, positive_when: :up)
        super(delta: delta,
              direction: direction || (delta.to_f.negative? ? :down : :up),
              period: period,
              positive_when: positive_when)
      end

      # What the card colours from.
      def good? = direction == positive_when

      # Its own state rather than a weak `up`: no change is not good news, and
      # painting it green would say it was.
      def flat? = delta.to_f.zero?
    end
  end
end
