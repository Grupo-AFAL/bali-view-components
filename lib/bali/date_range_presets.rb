# frozen_string_literal: true

module Bali
  # Named periods a date-range filter can carry instead of two literal dates.
  #
  # A preset travels through the query string under its own name — `q[created_at]=this_month`
  # — and only becomes a concrete range when {Bali::Types::DateRangeValue} casts it, on the
  # request that runs the query. That is the whole point of the indirection: a saved view or
  # a persisted filter holding `2026-08-01..2026-08-31` means August forever, while one
  # holding `this_month` still means this month next month.
  #
  # The range is built from `Time.zone` — the server's, the same zone every other date
  # filter already speaks. Resolving it in the browser would use the visitor's instead and
  # quietly disagree with the listing it filters.
  module DateRangePresets
    # Each period is a lambda and not a constant range: a constant would freeze at boot and
    # a long-lived process would keep filtering by the day it was deployed.
    #
    # Every one of them ends on `end_of_day`, like {Bali::Types::DateRangeValue} does for an
    # explicit range. A Date range would look right and read wrong — Rails casts both ends
    # to midnight, so the last day of the period would be cut off entirely.
    RANGES = {
      "today" => -> { day_range(Time.zone.today, Time.zone.today) },
      "this_week" => -> { day_range(Time.zone.today.beginning_of_week, Time.zone.today.end_of_week) },
      "this_month" => -> { day_range(Time.zone.today.beginning_of_month, Time.zone.today.end_of_month) },
      # Inclusive of today, which is what a listing filter is read to mean. The trailing
      # windows in `SelectOptions` end yesterday instead — that is an analytics widget,
      # where the day in progress skews the comparison.
      "last_7_days" => -> { day_range(Time.zone.today - 6, Time.zone.today) },
      "last_30_days" => -> { day_range(Time.zone.today - 29, Time.zone.today) }
    }.freeze

    TOKENS = RANGES.keys.freeze

    # The value the period select carries for "let me pick the dates myself". It is not a
    # preset and never reaches the cast: it names the *other* control, and what submits is
    # whatever the picker wrote.
    CUSTOM = "custom"

    class << self
      def token?(value)
        value.is_a?(String) && RANGES.key?(value)
      end

      # @return [Range, nil] nil for anything that is not a token, so a caller can fall
      #   through to parsing an explicit range.
      def resolve(value)
        return nil unless value.is_a?(String)

        RANGES[value]&.call
      end

      def label(token)
        I18n.t("bali_view.simple_filters.presets.#{token}")
      end

      # `[[label, token], ...]`, in the order given, ready for `options_for_select`.
      def options(tokens = TOKENS)
        Array(tokens).map { |token| [ label(token), token.to_s ] }
      end

      # Turn what a filter definition declared into the list of tokens the widget renders.
      # `true` means "all of them"; an array picks and orders them.
      #
      # Both the class-level DSL and the instance-level `simple_filters:` hashes come
      # through here, so a typo'd token fails the same way from either side rather than
      # rendering an option that filters nothing.
      #
      # @return [Array<String>, nil]
      def normalize(presets, key:, input:)
        return nil if presets.blank?

        unless input.to_s == "date_range"
          raise ArgumentError, "filter_attribute #{key}: presets: needs input: :date_range " \
                               "(got #{input.inspect}). A named period is a range — \"this week\" " \
                               "is not a value a single date can hold."
        end

        tokens = presets == true ? TOKENS.dup : Array(presets).map(&:to_s)
        unknown = tokens - TOKENS
        return tokens if unknown.empty?

        raise ArgumentError, "filter_attribute #{key}: unknown date range preset " \
                             "#{unknown.map(&:inspect).join(', ')} (valid: #{TOKENS.join(', ')})"
      end

      private

      def day_range(first, last)
        first.beginning_of_day..last.end_of_day
      end
    end
  end
end
