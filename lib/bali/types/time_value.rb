# frozen_string_literal: true

module Bali
  module Types
    class TimeValue < ActiveRecord::Type::String
      def cast(value)
        return nil if value.blank?

        value = time_string_to_seconds(value) if value.is_a?(String)
        value = integer_to_time(value) if value.is_a?(Numeric)

        value
      end

      def serialize(value)
        return value if value.blank? || value.is_a?(Numeric)
        return value.to_i if value.is_a?(String) && value.match(/\A\d+\Z/).present?
        return time_to_seconds(value) if value.is_a?(Time)

        time_string_to_seconds(value)
      end

      private

      def time_to_seconds(value)
        (value.hour * 3600) + (value.min * 60) + value.sec
      end

      def time_string_to_seconds(value)
        hours, minutes, seconds = value.match(/\d+:\d+(:\d+)?/)[0].split(':')
        (hours.to_i * 3600) + (minutes.to_i * 60) + seconds.to_i
      end

      def integer_to_time(value)
        Time.zone.local(today.year, today.month, today.day, *integer_to_hrs_mins_secs(value))
      end

      def integer_to_hrs_mins_secs(value)
        hours = value / 3600
        value -= (hours * 3600)

        minutes = value / 60
        value -= (minutes * 60)

        seconds = value
        [hours, minutes, seconds]
      end

      def today
        Date.current
      end
    end
  end
end
