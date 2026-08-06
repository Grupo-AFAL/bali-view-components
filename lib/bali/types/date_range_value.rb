# frozen_string_literal: true

require_relative "../date_range_presets"

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
        { en: " to ", es: " a " }[I18n.locale.to_sym]
      end

      def normalize_date_range(range)
        return if range.blank?
        return range unless range.is_a? String

        # A named period is checked first and before any parsing, because `today` and
        # `this_month` are names, not dates, and only this branch knows that.
        #
        # Nothing that used to cast to a usable range casts differently now — measured
        # token by token. Three of the five (`today`, `this_week`, `last_7_days`) reached
        # `Time.zone.parse`, came back nil and raised NoMethodError on `beginning_of_day`.
        # The other two did produce a range, and both were garbage: `Date._parse` reads
        # the "mon" inside `this_month` as a weekday and yields today, and it pulls
        # `mday: 30` out of `last_30_days` and yields the 30th of the current month. Those
        # are the only two strings whose result changes, from a silently wrong day to the
        # period they name. See Bali::DateRangePresets.
        preset = Bali::DateRangePresets.resolve(range)
        return preset if preset

        return parse_stringify_range(range) if range.include?("..")

        result = range.split(date_range_separator)

        # Searching in a day instead of date range
        result = [ result.first, result.first ] if result.size == 1

        result[0] = Time.zone.parse(result.first).beginning_of_day
        result[1] = Time.zone.parse(result.last).end_of_day
        result[0]..result[1]
      end

      def parse_stringify_range(range)
        start_range, end_range = range.split("..")
        if start_range.present? && end_range.present?
          Time.zone.parse(start_range)..Time.zone.parse(end_range)
        elsif start_range.present?
          Time.zone.parse(start_range)..
        elsif end_range.present?
          ..Time.zone.parse(end_range)
        end
      end
    end
  end
end
