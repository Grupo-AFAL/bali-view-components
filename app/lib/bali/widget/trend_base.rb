# frozen_string_literal: true

module Bali
  module Widget
    # A FIGURE AND HOW IT MOVED, with the history behind it.
    #
    #   class StudioFoundings < Bali::Widget::TrendBase
    #     default_size :medium
    #
    #     period_label "vs previous decade"
    #     series_labels { decades.keys.map(&:to_s) }
    #     series_values { decades.values }
    #
    #     def current  = decades.values.last
    #     def previous = decades.values[-2]
    #   end
    #
    # The base computes the delta. Every trend widget was hand-rolling
    # `(((latest - previous) / previous.to_f) * 100).round`; it is written once
    # here, and `current` / `previous` is a contract you cannot half-implement.
    class TrendBase < Base
      Trend = Data.define(:delta, :direction, :period, :positive_when, :unit) do
        def initialize(delta:, direction: nil, period: nil, positive_when: :up, unit: "%")
          super(delta: delta, direction: direction || (delta.to_f.negative? ? :down : :up),
                period: period, positive_when: positive_when, unit: unit)
        end

        # WHAT THE CARD COLOURS FROM, and never `direction`. Overdue tasks up 12%
        # and revenue up 12% are opposite news; a card reading the direction would
        # paint half a dashboard's trends the wrong way while looking confident.
        #
        # A flat trend is never good: no change is not news worth painting green.
        def good? = !flat? && direction == positive_when

        def flat? = delta.to_f.zero?
      end

      Series = Data.define(:labels, :values, :type) do
        def initialize(values:, labels: [], type: :line) = super

        def charted? = values.present?
      end

      # `:up` unless the widget says otherwise. A widget counting something BAD —
      # overdue work, low stock — declares `positive_when :down`, and a rising
      # number then reads red. Getting this wrong makes the card lie confidently,
      # which is why it is a declaration rather than a guess.
      class_attribute :_positive_when, default: :up
      class_attribute :_period_label
      class_attribute :_series_labels
      class_attribute :_series_values
      class_attribute :_series_type, default: :line

      class << self
        def positive_when(value) = self._positive_when = value

        def period_label(value) = self._period_label = value

        def series_labels(&block) = self._series_labels = block

        def series_values(&block) = self._series_values = block

        def series_type(value) = self._series_type = value
      end

      # The figure the card shows big.
      def current
        raise NotImplementedError, "#{self.class.name || 'This widget'} must define `#current`."
      end

      # What `current` is compared against. Return nil when there is nothing to
      # compare to — a widget's first week has no previous period, and the trend
      # is then ABSENT rather than zero.
      def previous
        raise NotImplementedError, "#{self.class.name || 'This widget'} must define `#previous`."
      end

      # `to_i` because a widget with no data at all has a nil `current`, and the
      # card asks `count.positive?`.
      def count = safely(0) { current.to_i }

      def trend
        safely(nil) do
          before = previous
          next if before.nil? || before.to_f.zero?

          Trend.new(delta: (((current - before) / before.to_f) * 100).round,
                    period: period_label, positive_when: _positive_when)
        end
      end

      def series
        safely(nil) do
          next if _series_values.nil?

          values = instance_exec(&_series_values)
          next if values.blank?

          Series.new(values: values, type: _series_type,
                     labels: _series_labels ? instance_exec(&_series_labels) : [])
        end
      end

      def period_label = _period_label
    end
  end
end
