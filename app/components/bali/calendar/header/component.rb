# frozen_string_literal: true

module Bali
  module Calendar
    module Header
      class Component < ApplicationViewComponent
        attr_reader :route_path, :period, :start_date, :period_switch, :start_attribute

        # @param start_date [Date|String] The date to start the calendar from.
        # @param period [Symbol] The period of the calendar, :month or :week.
        # @param route_path [String] The route to use for the links.
        # @param period_switch [Boolean] To display the period switch or not.
        # @param start_attribute [Symbol] Method to be called on each event object for the
        #  start_date.

        def initialize(start_date:, period: :month, route_path: '', period_switch: true,
                       start_attribute: :start_time, **options)
          @start_date = Date.parse(start_date.presence || Date.current.to_s)
          @period = (period || :month).to_sym
          @route_path = route_path
          @period_switch = period_switch
          @start_attribute = start_attribute
          @options = options
        end

        def prev_start_date
          if period == :month
            start_date.beginning_of_month - 1.month
          else
            start_date.beginning_of_week - 1.week
          end
        end

        def next_start_date
          if period == :month
            start_date.beginning_of_month + 1.month
          else
            start_date.beginning_of_week + 1.week
          end
        end

        def route(params = {})
          uri = URI.parse(route_path)
          uri.query = params.merge!(CGI.parse(uri.query.to_s)).to_query
          uri.to_s
        end

        def extra_params(type)
          parameters = {}
          parameters.merge!(start_attribute => prev_start_date, period: period) if type == :prev
          parameters.merge!(start_attribute => next_start_date, period: period) if type == :next
          parameters.merge!(period: 'week', start_attribute => start_date) if type == :week
          parameters.merge!(period: 'month', start_attribute => start_date) if type == :month
          parameters.merge!(@options[:extra_params]) if @options[:extra_params].present?
          parameters
        end
      end
    end
  end
end
