# frozen_string_literal: true

module Bali
  module Gauge
    # A radial progress ring — the circular half of what `Bali::Progress` does
    # linearly.
    #
    #   render Bali::Gauge::Component.new(value: 7, max: 10, label: "shifts")
    #
    # daisyUI's `radial-progress` underneath, which is CSS-only: no canvas and no
    # JavaScript, so a dashboard of twelve rings costs nothing a dashboard of
    # twelve empty boxes does not. That is why the ring ladder is cheap where the
    # chart ladder is not.
    #
    # A component rather than the raw daisyUI class at the call site, per the
    # composition rule in `.claude/CLAUDE.md` — and because daisyUI's own example
    # emits no ARIA at all, which is the part below that actually matters.
    class Component < ApplicationViewComponent
      COLORS = {
        primary: "text-primary",
        secondary: "text-secondary",
        accent: "text-accent",
        neutral: "text-neutral",
        info: "text-info",
        success: "text-success",
        warning: "text-warning",
        error: "text-error"
      }.freeze

      # `--size` and `--thickness` are daisyUI's own custom properties. Named
      # sizes rather than a free number so a dashboard's rings match each other.
      SIZES = {
        sm: "[--size:3rem] [--thickness:3px] text-xs",
        md: "[--size:4.5rem] [--thickness:4px] text-sm",
        lg: "[--size:7rem] [--thickness:6px] text-lg"
      }.freeze

      def initialize(value:, max: 100, label: nil, size: :md, color: :primary,
                     show_percentage: true, **options)
        @value = value
        @max = max
        @label = label
        @size = size.to_sym
        @color = color&.to_sym
        @show_percentage = show_percentage
        @options = options
        super()
      end

      # CLAMPED, and only for drawing: a ring has nowhere to put the eleventh of
      # ten, but "11 / 10" is a real and good state the caller may still want to
      # print beside it. This is the ONLY implementation — `Bali::Widget::Goal`
      # says what the goal is and this draws it.
      #
      # A `max` of zero is "no goal set" rather than an error — dividing by it
      # would take a page down over a configuration mistake.
      def percentage
        return 0 if max.to_f.zero?

        ((value.to_f / max.to_f) * 100).clamp(0.0, 100.0).round
      end

      def show_percentage? = @show_percentage

      # The ring is a `progressbar`, and it needs the whole quartet: daisyUI
      # draws the arc with a CSS custom property, which assistive technology
      # cannot see at all. Without these the control is invisible rather than
      # merely unlabelled.
      #
      # `aria-valuenow` carries the UNCLAMPED value, because that is the true
      # reading; only the drawing is clamped.
      def aria_attributes
        {
          role: "progressbar",
          "aria-valuenow": value,
          "aria-valuemin": 0,
          "aria-valuemax": max,
          "aria-label": label.presence || t("bali_view.gauge.default_label", percentage: percentage)
        }
      end

      private

      attr_reader :value, :max, :label, :size, :color, :options

      def gauge_classes
        class_names("radial-progress", COLORS[color], SIZES.fetch(size, SIZES[:md]),
                    options[:class])
      end

      def gauge_attributes
        options.except(:class, :style)
      end

      # daisyUI reads the arc from `--value`, so this one inline custom property
      # is the component's whole geometry. An exception to the no-inline-styles
      # rule that cannot be avoided: the value is per-instance and runtime, which
      # is exactly what Tailwind cannot compile a class for.
      def gauge_style
        "--value:#{percentage};#{options[:style]}"
      end
    end
  end
end
