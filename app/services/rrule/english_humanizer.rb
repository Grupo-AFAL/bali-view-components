# frozen_string_literal: true

# rubocop: disable Metrics/ClassLength
# rubocop: disable Metrics/AbcSize
# rubocop: disable Metrics/CyclomaticComplexity
# rubocop: disable Metrics/PerceivedComplexity
module Rrule
  # Based off https://github.com/jakubroztocil/rrule/blob/master/src/nlp/totext.ts
  #
  class EnglishHumanizer
    attr_reader :rrule, :options

    OPTION_ATTRIBUTE_RE = /_option/

    DAY_NAMES = %w[
      sunday
      monday
      tuesday
      wednesday
      thursday
      friday
      saturday
    ].freeze

    MONTH_NAMES = %w[
      January
      February
      March
      April
      May
      June
      July
      August
      September
      October
      November
      December
    ].freeze

    def initialize(rrule, options)
      @rrule = rrule
      @options = options

      # Define instance method for each of the options.
      options.each { |name, value| define_singleton_method("#{name}_option") { value } }
    end

    def to_s
      @buffer = 'every'

      send freq_option.downcase

      if count_option
        add 'for'
        add count_option
        add plural?(count_option) ? 'times' : 'time'
      end

      if until_option
        add "until #{MONTH_NAMES[until_option.month - 1]} #{until_option.day}, " \
            "#{until_option.year}"
      end

      @buffer
    end

    # Return nil if we're trying to access an option that isn't present.
    def method_missing(method_name, *args)
      if method_name.to_s.match?(OPTION_ATTRIBUTE_RE)
        nil
      else
        super
      end
    end

    def respond_to_missing?(method_name)
      super || method_name.to_s.match?(OPTION_ATTRIBUTE_RE)
    end

    protected

    def list(arr, formatter, final_delimiter = nil, delimiter: ',')
      *rest, middle, tail = arr.map(&formatter)

      if final_delimiter
        [*rest, [middle, tail].compact.join(" #{final_delimiter} ")].join("#{delimiter} ")
      else
        [*rest, middle, tail].compact.join("#{delimiter} ")
      end
    end

    def add(string)
      @buffer += " #{string}"
    end

    def plural?(num)
      num.to_i % 100 != 1
    end

    def daily
      add interval_option if interval_option != 1

      add plural?(interval_option) ? 'days' : 'day'
    end

    def yearly
      add interval_option if interval_option != 1
      add plural?(interval_option) ? 'years' : 'year'

      if bysetpos_option
        add 'on the'
        add _bybysetpos
        add list(byweekday_option, method(:weekdaytext))
        add 'of'
        add list(options.fetch(:bymonth), method(:monthtext), 'and')
      else
        add 'on' if bymonthday_option || bymonth_option
        add list(options.fetch(:bymonth), method(:monthtext), 'and') if bymonth_option
        add list (bymonthday_option.map { |o| nth(o) }), :to_s, 'and' if bymonthday_option
      end
    end

    def weekly
      add interval_option if interval_option != 1
      add plural?(interval_option) ? 'weeks' : 'week'

      if byweekday_option && weekdays?
        add 'on weekdays'
      elsif byweekday_option && every_day?
        add 'everyday'
      else
        if bymonth_option
          add 'on'
          _bymonth
        end

        if bymonthday_option
          _bymonthday
        elsif byweekday_option
          add 'on'
          _byweekday
        end
      end
    end

    def monthly
      add interval_option if interval_option != 1
      add plural?(interval_option) ? 'months' : 'month'
      add "on #{_bybysetpos}" if bysetpos_option

      if bymonthday_option
        _bymonthday
      elsif byweekday_option && weekdays?
        add 'on weekdays'
      elsif byweekday_option || bynweekday_option
        _byweekday
      end
    end

    def weekdaytext(day)
      [day.ordinal && nth(day.ordinal), DAY_NAMES[day.index]].compact.join(' ')
    end

    def monthtext(month)
      MONTH_NAMES[month - 1]
    end

    def all_weeks?
      bynweekday_option.all? { |option| option.ordinal.nil? }
    end

    def every_day?
      byweekday_option.sort_by(&:index).map { |day| RRule::WEEKDAYS[day.index] } == RRule::WEEKDAYS
    end

    def weekdays?
      return false if byweekday_option.none?

      byweekday_option.sort_by(&:index).map do |day|
        RRule::WEEKDAYS[day.index]
      end == RRule::WEEKDAYS - %w[SA SU]
    end

    def _bymonth
      add list(options.fetch(:bymonth), method(:monthtext), 'y')
    end

    def _byweekday
      return unless byweekday_option.any?

      add list(byweekday_option, method(:weekdaytext))
    end

    def _bymonthday
      add 'in the'
      add list (bymonthday_option.map { |o| nth(o) }), :to_s, 'y'
      add 'of month'
    end

    def nth(ordinal)
      return 'last' if ordinal == -1

      nth = ordinal.abs
      ordinal.negative? ? "#{nth} last" : nth
    end

    def bysetpostext(value)
      value.to_i == -1 ? 'last' : "#{value}º"
    end

    def _bybysetpos
      list(bysetpos_option, method(:bysetpostext), 'y')
    end

    def hourly
      add interval_option if interval_option != 1
      add plural?(interval_option) ? 'hours' : 'hour'
    end
  end
end
# rubocop: enable Metrics/PerceivedComplexity
# rubocop: enable Metrics/CyclomaticComplexity
# rubocop: enable Metrics/AbcSize
# rubocop: enable Metrics/ClassLength
