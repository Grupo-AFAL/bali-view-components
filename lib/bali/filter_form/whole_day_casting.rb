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

      # Both read the date as the END of that day, so "on or before the 27th" and "after the
      # 27th" stay complementary over a datetime column.
      END_OF_DAY_PREDICATES = %w[_lteq _gt].freeze

      private

      def cast_whole_days(params)
        groups = params[:g]
        return params if groups.nil?

        params.merge(g: cast_whole_day_groupings(groups))
      end

      # Same walk as EnumCasting#cast_enum_groupings: a nested `g` can arrive as a hash or an array.
      def cast_whole_day_groupings(groupings)
        return groupings.map { |group| cast_whole_day_group(group) } if groupings.is_a?(Array)
        return groupings unless groupings.is_a?(Hash)

        groupings.transform_values { |group| cast_whole_day_group(group) }
      end

      def cast_whole_day_group(group)
        return group unless group.is_a?(Hash)

        group.to_h do |key, value|
          name = key.to_s
          casted =
            if EnumCasting::GROUPING_KEYS.include?(name) then cast_whole_day_groupings(value)
            elsif name.end_with?(*END_OF_DAY_PREDICATES) then end_of_day(value)
            else value
            end
          [ key, casted ]
        end
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
