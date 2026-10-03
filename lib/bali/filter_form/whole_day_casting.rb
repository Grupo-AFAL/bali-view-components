# frozen_string_literal: true

module Bali
  class FilterForm
    # The advanced panel's range picker sends both ends as bare dates, and Ransack casts a bare
    # date on a datetime column to that day's midnight: `created_at_lteq=2026-08-27` stopped at
    # 2026-08-27 00:00 and left the last day out (#1282). Over a copy, like EnumCasting, so the
    # rendered state keeps the date the picker sent.
    module WholeDayCasting
      extend ActiveSupport::Concern

      # What condition_controller.js#syncRangeDates and the timeless format of
      # datepicker-controller.js#dateFormat write: change the three together.
      BARE_DATE = /\A\d{4}-\d{2}-\d{2}\z/

      private

      def cast_whole_days(params)
        groups = params[:g]
        return params unless groups.is_a?(Hash)

        params.merge(g: groups.transform_values { |group| cast_whole_day_group(group) })
      end

      def cast_whole_day_group(group)
        return group unless group.is_a?(Hash)

        group.to_h { |key, value| [ key, key.to_s.end_with?("_lteq") ? end_of_day(value) : value ] }
      end

      # A date column gets the same day back: Ransack casts the time with `to_date`, in the zone.
      def end_of_day(value)
        return value unless value.is_a?(String) && value.match?(BARE_DATE)

        Time.zone.parse(value).end_of_day
      rescue ArgumentError
        value
      end
    end
  end
end
