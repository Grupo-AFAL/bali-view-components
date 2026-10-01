# frozen_string_literal: true

module Bali
  module Calendar
    module Header
      class Component < ApplicationViewComponent
        include Normalization

        # Exactly this pair, in this order: adding :year here would put a third
        # button on every host that never touched `period_switch:`.
        DEFAULT_SWITCH_PERIODS = %i[week month].freeze

        attr_reader :route_path, :period, :start_date, :period_switch, :start_attribute,
                    :min_date, :max_date

        # @param start_date [Date|String] The date to start the calendar from.
        # @param period [Symbol] The period of the calendar: :month, :week, :day or :year.
        # @param route_path [String] The route to use for the links. Its query string is
        #   carried over to every link, with `start_attribute` and `period` merged on
        #   top — a host key that depends on the date (`year=2026` next to
        #   `date=2027-01-01`) goes in `drop_params`.
        # @param period_switch [Boolean, Array<Symbol>] `true` renders `%i[week month]`,
        #   `false` renders nothing, an array names the buttons — `%i[month year]`.
        # @param start_attribute [Symbol] Method to be called on each event object for the
        #  start_date.
        # @param min_date [Date, String, nil] Earliest date the arrows may navigate to;
        #   nil is no limit. The previous arrow is disabled once the period before this
        #   one no longer contains it.
        # @param max_date [Date, String, nil] Latest date, the mirror of `min_date`.
        # @param drop_params [Array<Symbol, String>] Keys of `route_path`'s query string
        #   that the header's links leave out.
        # rubocop:disable Metrics/ParameterLists
        def initialize(start_date:, period: :month, route_path: "", period_switch: true,
                       start_attribute: :start_time, min_date: nil, max_date: nil,
                       drop_params: [], **options)
          # rubocop:enable Metrics/ParameterLists
          @start_date = normalize_date(start_date)
          @period = normalize_period(period)
          @route_path = route_path
          @period_switch = period_switch
          @start_attribute = start_attribute
          @min_date = min_date&.to_date
          @max_date = max_date&.to_date
          @drop_params = Array(drop_params).map(&:to_s)
          @options = options
        end

        def prev_start_date
          period_start(start_date) - period_step
        end

        def next_start_date
          period_start(start_date) + period_step
        end

        # Compared on the period, not the day: `min_date: "2020-06-15"` still lets a
        # year view reach 2020 and a month view reach June 2020.
        def prev_in_range?
          min_date.nil? || prev_start_date >= period_start(min_date)
        end

        def next_in_range?
          max_date.nil? || next_start_date <= period_start(max_date)
        end

        # Disabled rather than left out: measured at 1440px, removing one arrow
        # moves the title 25px, half the arrow's 50px.
        def arrow_options(type)
          in_range = type == :prev ? prev_in_range? : next_in_range?
          label = t("bali_view.calendar.header.#{type == :prev ? 'previous' : 'next'}")

          {
            href: route(extra_params(type)), variant: :ghost, disabled: !in_range,
            aria: { label: label, disabled: (true unless in_range) }.compact
          }
        end

        # @return [Array<Symbol>] The periods the switch offers, in render order.
        #   Filtered against PERIODS so a stray value never reaches the translation.
        def switch_periods
          @switch_periods ||= if period_switch.is_a?(Array)
            period_switch.map(&:to_sym) & Bali::Calendar::Component::PERIODS
          elsif period_switch
            DEFAULT_SWITCH_PERIODS
          else
            [].freeze
          end
        end

        def period_switch?
          switch_periods.any? && route_path.present?
        end

        # With a period that is not on the switch (`:day` and the default pair) every
        # button renders solid, which is what this header always produced there.
        def switch_style(switch_period)
          :outline if switch_periods.include?(period) && period != switch_period
        end

        def route(params = {})
          uri.query = query_params.except(*@drop_params).merge(params).to_query
          uri.to_s
        end

        def uri
          @uri ||= URI.parse(route_path)
        end

        def query_params
          @query_params ||= Rack::Utils.parse_query(uri.query.to_s)
        end

        def extra_params(type)
          base_params = case type
          when :prev then { start_attribute => prev_start_date, period: period }
          when :next then { start_attribute => next_start_date, period: period }
          when *Bali::Calendar::Component::PERIODS then { period: type, start_attribute => start_date }
          else {}
          end

          base_params.merge(@options[:extra_params] || {})
        end

        private

        def period_start(date)
          case period
          when :year then date.beginning_of_year
          when :month then date.beginning_of_month
          else date.beginning_of_week
          end
        end

        def period_step
          case period
          when :year then 1.year
          when :month then 1.month
          else 1.week
          end
        end
      end
    end
  end
end
