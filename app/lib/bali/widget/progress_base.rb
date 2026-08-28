# frozen_string_literal: true

module Bali
  module Widget
    # PROGRESS TOWARD A GOAL, and how you got there.
    #
    #   class ProjectProgress < Bali::Widget::ProgressBase
    #     default_size :large
    #
    #     goal_label { "of #{Task.count}" }
    #     series_values { Task.group(:status).count.values }
    #
    #     def value = Task.where(status: :done).count
    #     def max   = Task.count
    #   end
    #
    # The ring REPLACES the number as the headline, which is what makes this a
    # different pattern rather than a list with a decoration.
    class ProgressBase < Base
      Goal = Data.define(:value, :max, :label) do
        def initialize(value:, max: 100, label: nil) = super

        # CLAMPED for drawing only: 11 of 10 shifts covered is a real and good
        # state that a ring has nowhere to put, so `value` still reads true.
        # A `max` of zero is "no goal set" — a configuration state, not an error,
        # and dividing by it would take a page down over one misconfiguration.
        def percentage
          return 0.0 if max.to_f.zero?

          (value.to_f / max.to_f * 100).clamp(0.0, 100.0)
        end
      end

      Series = TrendBase::Series

      class_attribute :_goal_label, **Base::ATTRIBUTE_OPTIONS
      class_attribute :_series_labels, **Base::ATTRIBUTE_OPTIONS
      class_attribute :_series_values, **Base::ATTRIBUTE_OPTIONS
      class_attribute :_series_type, default: :bar, **Base::ATTRIBUTE_OPTIONS

      class << self
        def goal_label(value = nil, &block) = self._goal_label = value || block

        def series_labels(&block) = self._series_labels = block

        def series_values(&block) = self._series_values = block

        def series_type(value) = self._series_type = value
      end

      # How far along.
      def value
        raise NotImplementedError, "#{self.class.name || 'This widget'} must define `#value`."
      end

      # What counts as done. Defaults to a percentage's worth, so a widget whose
      # figure is already a percentage implements `value` alone.
      def max = 100

      # The ring is the headline, but `count` still gates the empty state and the
      # "view all" link, so it answers with what has been achieved.
      def count = @count ||= safely(0) { value.to_i }

      def goal
        safely(nil) do
          Goal.new(value: value, max: max, label: resolved_goal_label)
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

      private

      def resolved_goal_label
        _goal_label.is_a?(Proc) ? instance_exec(&_goal_label) : _goal_label
      end
    end
  end
end
