# frozen_string_literal: true

module Bali
  module Widget
    # Progress toward a goal — the third ladder, where the headline is a ring
    # rather than a number.
    #
    # `max` rather than a bare percentage so the card can render "7 / 10 shifts"
    # as well as 70%. A widget that only has a percentage passes `value:` alone
    # and takes the default.
    Gauge = Data.define(:value, :max, :label) do
      def initialize(value:, max: 100, label: nil)
        super
      end

      # CLAMPED for drawing, and only for drawing: 11 of 10 shifts covered is a
      # real and good state, but a ring has nowhere to put the eleventh. `value`
      # still reads true, so the card can say "11 / 10" beside a full ring.
      #
      # A `max` of zero means "no goal set", which is a configuration state and
      # not an error — dividing by it would take the whole dashboard down for one
      # misconfigured widget.
      def percentage
        return 0.0 if max.to_f.zero?

        (value.to_f / max.to_f * 100).clamp(0.0, 100.0)
      end
    end
  end
end
