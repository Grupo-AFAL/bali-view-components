# frozen_string_literal: true

module Bali
  module Calendar
    module Header
      class Component < ApplicationViewComponent
        include Normalization

        # What `period_switch: true` has always meant. It stays exactly this pair, in
        # this order: every host that has never touched the keyword must keep seeing
        # the two buttons it sees today and no third one.
        DEFAULT_SWITCH_PERIODS = %i[week month].freeze

        attr_reader :route_path, :period, :start_date, :period_switch, :start_attribute

        # @param start_date [Date|String] The date to start the calendar from.
        # @param period [Symbol] The period of the calendar: :month, :week, :day or :year.
        # @param route_path [String] The route to use for the links.
        # @param period_switch [Boolean, Array<Symbol>] `true` renders the historical
        #   `%i[week month]` pair, `false` renders nothing, and an array names the
        #   buttons to render — `period_switch: %i[month year]`. Opting the year in has
        #   to be explicit, because `true` adding a button would change every existing
        #   calendar's header without anyone asking for it.
        # @param start_attribute [Symbol] Method to be called on each event object for the
        #  start_date.

        def initialize(start_date:, period: :month, route_path: "", period_switch: true,
                       start_attribute: :start_time, **options)
          @start_date = normalize_date(start_date)
          @period = normalize_period(period)
          @route_path = route_path
          @period_switch = period_switch
          @start_attribute = start_attribute
          @options = options
        end

        def prev_start_date
          case period
          when :year then start_date.beginning_of_year - 1.year
          when :month then start_date.beginning_of_month - 1.month
          else start_date.beginning_of_week - 1.week
          end
        end

        def next_start_date
          case period
          when :year then start_date.beginning_of_year + 1.year
          when :month then start_date.beginning_of_month + 1.month
          else start_date.beginning_of_week + 1.week
          end
        end

        # @return [Array<Symbol>] The periods the switch offers, in render order.
        #   An array is filtered against PERIODS so a stray value cannot reach the
        #   translation lookup; anything truthy that is not an array keeps meaning
        #   "the historical pair", which is what it meant before this took arrays.
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

        # `:outline` marks the periods that are NOT the current one — but only when
        # the current one is on the switch at all. With `period: :day` and the default
        # pair, neither button is current and both render solid, which is what this
        # header has always produced for that combination.
        def switch_style(switch_period)
          :outline if switch_periods.include?(period) && period != switch_period
        end

        def route(params = {})
          uri.query = query_params.merge(params).to_query
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
          # `period` as a String here and as a Symbol above is a pre-existing
          # inconsistency; both survive `to_query` identically, and changing it
          # would be an unrelated churn in every host's query string.
          when *Bali::Calendar::Component::PERIODS then { period: type.to_s, start_attribute => start_date }
          else {}
          end

          base_params.merge(@options[:extra_params] || {})
        end
      end
    end
  end
end
