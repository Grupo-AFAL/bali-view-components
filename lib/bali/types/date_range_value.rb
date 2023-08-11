# frozen_string_literal: true

module Bali
  module Types
    class DateRangeValue < ActiveRecord::Type::String
      def cast(value)
        normalize_date_range(value)
      end

      def serialize(value)
        value
      end

      private

      def date_range_separator
        { en: ' to ', es: ' a ' }[I18n.locale]
      end

      def normalize_date_range(range)
        return range unless range.is_a? String

        result = range.split(date_range_separator)

        # Searching in a day instead of date range
        result = [result.first, result.first] if result.size == 1

        result[0] = Time.zone.parse(result.first).beginning_of_day
        result[1] = Time.zone.parse(result.last).end_of_day
        result[0]..result[1]
      end
    end
  end
end
