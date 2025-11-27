# frozen_string_literal: true

# rubocop: disable Metrics/ClassLength
# rubocop: disable Metrics/CyclomaticComplexity
# rubocop: disable Metrics/PerceivedComplexity
# rubocop: disable Metrics/AbcSize
module Rrule
  # Based off https://github.com/jakubroztocil/rrule/blob/master/src/nlp/totext.ts
  #
  class SpanishHumanizer
    attr_reader :rrule, :options

    OPTION_ATTRIBUTE_RE = /_option/

    DAY_NAMES = %w[
      domingo
      lunes
      martes
      miércoles
      jueves
      viernes
      sábado
    ].freeze

    MONTH_NAMES = %w[
      enero
      febrero
      marzo
      abril
      mayo
      junio
      julio
      augosto
      septiembre
      octubre
      noviembre
      diciembre
    ].freeze

    def initialize(rrule, options)
      @rrule = rrule
      @options = options

      # Define instance method for each of the options.
      options.each { |name, value| define_singleton_method("#{name}_option") { value } }
    end

    def to_s
      @buffer = 'cada'

      send freq_option.downcase

      if count_option
        add 'por'
        add count_option
        add plural?(count_option) ? 'veces' : 'vez'
      end

      if until_option
        add "hasta el #{until_option.day} " \
            "de #{MONTH_NAMES[until_option.month - 1]} de #{until_option.year}"
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

      add plural?(interval_option) ? 'días' : 'día'
    end

    def yearly
      add interval_option if interval_option != 1
      add plural?(interval_option) ? 'años' : 'año'

      if bysetpos_option
        add 'en el'
        add _bybysetpos
        add list(byweekday_option, method(:weekdaytext))
        add 'de'
        add list(options.fetch(:bymonth), method(:monthtext), 'y')
      else
        add 'el' if bymonthday_option || bymonth_option
        add list (bymonthday_option.map { |o| nth(o) }), :to_s, 'y' if bymonthday_option
        add list(options.fetch(:bymonth), method(:monthtext), 'y') if bymonth_option
      end
    end

    def weekly
      add interval_option if interval_option != 1
      add plural?(interval_option) ? 'semanas' : 'semana'

      if byweekday_option && weekdays?
        add 'en días laborales'
      elsif byweekday_option && every_day?
        add 'todos los días'
      else
        if bymonth_option
          add 'en'
          _bymonth
        end

        if bymonthday_option
          _bymonthday
        elsif byweekday_option
          add 'el'
          _byweekday
        end
      end
    end

    def monthly
      add interval_option if interval_option != 1
      add plural?(interval_option) ? 'meses' : 'mes'
      add "en el #{_bybysetpos}" if bysetpos_option

      if bymonthday_option
        _bymonthday
      elsif byweekday_option && weekdays?
        add 'en días laborales'
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
      add 'en el'
      add list (bymonthday_option.map { |o| nth(o) }), :to_s, 'y'
      add 'del mes'
    end

    def nth(ordinal)
      return 'último' if ordinal == -1

      nth = ordinal.abs
      ordinal.negative? ? "#{nth} último" : nth
    end

    def bysetpostext(value)
      value.to_i == -1 ? 'último' : "#{value}º"
    end

    def _bybysetpos
      list(bysetpos_option, method(:bysetpostext), 'y')
    end

    def hourly
      add interval_option if interval_option != 1
      add plural?(interval_option) ? 'horas' : 'hora'
    end
  end
end
# rubocop: enable Metrics/AbcSize
# rubocop: enable Metrics/PerceivedComplexity
# rubocop: enable Metrics/CyclomaticComplexity
# rubocop: enable Metrics/ClassLength
