# frozen_string_literal: true

module Bali
  module Calendar
    module Header
      class Component < ApplicationViewComponent
        attr_reader :route_name, :period, :start_date, :period_switch, :start_attribute

        def initialize(start_date:, period: :month, route_name: nil, period_switch: true,
                       start_attribute: :start_time, **options)
          @start_date = Date.parse(start_date.presence || Date.current.to_s)
          @period = (period || :month).to_sym
          @route_name = route_name
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

        # rubocop:disable Metrics/AbcSize
        def extra_params(type)
          parameters = {}
          parameters.merge!(start_attribute => prev_start_date, period: period) if type == :prev
          parameters.merge!(start_attribute => next_start_date, period: period) if type == :next
          parameters.merge!(period: 'week', start_attribute => start_date) if type == :week
          parameters.merge!(period: 'month', start_attribute => start_date) if type == :month
          parameters.merge!(@options[:extra_params]) if @options[:extra_params].present?
          parameters
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
