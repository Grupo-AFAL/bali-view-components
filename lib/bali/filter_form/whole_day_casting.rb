# frozen_string_literal: true

module Bali
  class FilterForm
    # The advanced panel's range picker sends both ends as bare dates, and Ransack casts a bare
    # date on a datetime column to that day's midnight: `created_at_lteq=2026-08-27` stopped at
    # 2026-08-27 00:00 and left the last day out (#1282), and `created_at_eq=2026-08-27` matched
    # only a row created at that exact midnight. Over a copy, like EnumCasting, so the rendered
    # state keeps the date the picker sent.
    module WholeDayCasting
      extend ActiveSupport::Concern

      # What condition_controller.js#syncRangeDates and the timeless format of
      # datepicker-controller.js#dateFormat write: change the three together.
      BARE_DATE = /\A\d{4}-\d{2}-\d{2}\z/

      # Both read the date as the END of that day, so "on or before the 27th" and "after the
      # 27th" stay complementary over a datetime column.
      END_OF_DAY_PREDICATES = %w[_lteq _gt].freeze

      # The only column types `_eq` is widened on: Ransack casts a bare date to midnight on
      # these (Ransack::Nodes::Value#cast, which also lists `:time`, a time of day with no day
      # to widen). A date column already answers `_eq` with the day, and a string column
      # holding dates answers it exactly.
      TIMESTAMP_TYPES = %i[datetime timestamp timestamptz].freeze

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

        whole_days = {}
        casted = group.each_with_object({}) do |(key, value), result|
          name = key.to_s
          if EnumCasting::GROUPING_KEYS.include?(name) then result[key] = cast_whole_day_groupings(value)
          elsif (grouping = whole_day_grouping(name, value)) then whole_days[name] = grouping
          elsif name.end_with?(*END_OF_DAY_PREDICATES) then result[key] = end_of_day(value)
          else result[key] = value
          end
        end
        whole_days.empty? ? casted : with_nested_groupings(casted, whole_days)
      end

      # A date column gets the same day back: Ransack casts the time with `to_date`, in the zone.
      def end_of_day(value)
        return value unless value.is_a?(String) && value.match?(BARE_DATE)

        Time.zone.parse(value).end_of_day
      rescue ArgumentError
        value
      end

      # "On the 27th" as a group of its own rather than as `_gteq`/`_lteq` pairs beside the
      # others: the group it sits in may be an OR, and its siblings may already use those keys.
      def whole_day_grouping(key, value)
        return unless value.is_a?(String) && value.match?(BARE_DATE)
        return unless Ransack::Predicate.detect_from_string(key) == "eq"
        return unless timestamp_condition?(key, value)

        attribute = key.delete_suffix("_eq")
        day = Time.zone.parse(value)
        { "m" => "and", "#{attribute}_gteq" => day.beginning_of_day, "#{attribute}_lteq" => day.end_of_day }
      rescue ArgumentError
        nil
      end

      # Ransack's own resolution — aliases, association paths, ransackers — over a throwaway
      # search. One attribute only: `a_or_b_eq` split into two ranges would no longer ask
      # whether EITHER falls on that day.
      def timestamp_condition?(key, value)
        condition = ransack_condition(key, value)
        condition&.attributes&.one? && TIMESTAMP_TYPES.include?(condition.default_type)
      end

      # Keyed by the condition each one replaces, a key no sibling group's index can take; and a
      # hash, the indexed shape FilterForm#extract_groupings gives the top-level `g`.
      def with_nested_groupings(group, groupings)
        key = group.key?(:g) ? :g : "g"
        nested = group[key]
        nested = nested.each_with_index.to_h { |inner, index| [ index.to_s, inner ] } if nested.is_a?(Array)
        group.merge(key => (nested.is_a?(Hash) ? nested : {}).merge(groupings))
      end
    end
  end
end
