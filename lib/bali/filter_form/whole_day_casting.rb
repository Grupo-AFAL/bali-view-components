# frozen_string_literal: true

module Bali
  class FilterForm
    # The advanced panel's range picker sends both ends as bare dates, and Ransack casts a bare
    # date on a datetime column to that day's midnight: `created_at_lteq=2026-08-27` stopped at
    # 2026-08-27 00:00 and left the last day out (#1282), and `created_at_eq=2026-08-27` matched
    # only a row created at that exact midnight. A `type: :datetime` picker's minute missed the
    # same way one unit down: `created_at_eq=2026-08-27 21:22:00` left out a row created at
    # 21:22:37 (#1333). Over a copy, like EnumCasting, so the rendered state keeps the value the
    # picker sent.
    module WholeDayCasting
      extend ActiveSupport::Concern

      # What condition_controller.js#syncRangeDates and the timeless format of
      # datepicker-controller.js#dateFormat write: change the three together.
      BARE_DATE = /\A\d{4}-\d{2}-\d{2}\z/

      # The timed format of datepicker-controller.js#dateFormat. Its seconds are always 00: the
      # panel's picker has no control for them, so seconds written by hand compare as written.
      BARE_MINUTE = /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:00\z/

      # Both read the value as the END of its day or minute, so "on or before the 27th" and
      # "after the 27th" stay complementary over a datetime column.
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

        params.merge(g: groups.transform_values { |group| cast_whole_day_group(group) })
      end

      # The rest of `q`, where the SimpleFilters `:date` widget sends its `_eq`, once
      # FilterForm#nest_panel_groupings has taken the panel's groups and their combinator into a
      # group of their own: the root is an AND by then, so a day added to its `g` sits beside
      # the panel's group. Added any earlier, it would be nested inside the panel's OR.
      def cast_root_whole_days(params)
        root = cast_whole_day_group(params.except(:g))
        groups = params.fetch(:g, {}).merge(root.delete("g") || {})
        groups.empty? ? root : root.merge(g: groups)
      end

      def cast_whole_day_group(group)
        whole_days = {}
        casted = group.each_with_object({}) do |(key, value), result|
          name = key.to_s
          if (grouping = whole_day_grouping(name, value)) then whole_days[name] = grouping
          elsif name.end_with?(*END_OF_DAY_PREDICATES) then result[key] = end_of_day(value)
          else result[key] = value
          end
        end
        whole_days.empty? ? casted : casted.merge("g" => whole_days)
      end

      # Of the minute too, for a bare minute. A date column gets the same day back: Ransack casts
      # the time with `to_date`, in the zone.
      def end_of_day(value)
        picked_span(value)&.end || value
      end

      # "On the 27th" as a group of its own rather than as `_gteq`/`_lteq` pairs beside the
      # others: the group it sits in may be an OR, and its siblings may already use those keys.
      def whole_day_grouping(key, value)
        return unless (span = picked_span(value))
        return unless Ransack::Predicate.detect_from_string(key) == "eq"
        return unless timestamp_condition?(key, value)

        attribute = key.delete_suffix("_eq")
        { "m" => "and", "#{attribute}_gteq" => span.begin, "#{attribute}_lteq" => span.end }
      end

      def picked_span(value)
        return unless value.is_a?(String)

        if value.match?(BARE_DATE)
          Time.zone.parse(value).all_day
        elsif value.match?(BARE_MINUTE)
          minute = Time.zone.parse(value)
          minute.beginning_of_minute..minute.end_of_minute
        end
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
    end
  end
end
