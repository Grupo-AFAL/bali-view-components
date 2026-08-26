# frozen_string_literal: true

module Bali
  module Widget
    # Progress toward a goal — the third ladder, where the headline is a ring
    # rather than a number.
    #
    # `Goal`, not `Gauge`, and the reason is not taste: a `Bali::Widget::Gauge`
    # sitting beside `Bali::Gauge::Component` means that inside `Bali::Widget`
    # the natural `Gauge::Component` resolves to `Bali::Widget::Gauge::Component`
    # and raises — the same constant-resolution trap `.claude/CLAUDE.md`
    # documents for preview files. It also names the right thing: this is the
    # GOAL, and the gauge is what draws it.
    #
    # `max` rather than a bare percentage so the card can render "7 / 10 shifts"
    # as well as 70%. A widget that only has a percentage passes `value:` alone
    # and takes the default.
    Goal = Data.define(:value, :max, :label) do
      def initialize(value:, max: 100, label: nil)
        super
      end

      # NO `percentage` HERE. `Bali::Gauge::Component` owns the arithmetic and
      # the clamping — this object's job is to say what the goal IS, and a second
      # implementation next to it was two sets of rounding rules with one caller
      # between them.
    end
  end
end
