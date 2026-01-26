# frozen_string_literal: true

module Bali
  module Calendar
    class Component < ApplicationViewComponent
      PERIODS = %i[month week day].freeze

      # Public readers for template access
      attr_reader :start_date, :period, :start_attribute, :show_date, :template

      renders_one :footer
      renders_one :header, ->(route_path: nil, period_switch: true, **options) do
        Header::Component.new(
          start_date: @start_date.to_s,
          period: @period,
          route_path: route_path,
          period_switch: period_switch,
          start_attribute: @start_attribute,
          **options
        )
      end

      # @param template [String] Path to an HTML template with the content of each day.
      # @param start_date [Date, String] The date to start the calendar from.
      # @param period [Symbol] The period of the calendar: :month, :week, or :day.
      # @param events [Array] Events to display, must respond to `start_attribute`.
      # @param start_attribute [Symbol] Method to call on each event for the start date.
      # @param end_attribute [Symbol] Method to call on each event for the end date.
      # @param weekdays_only [Boolean] Show only Monday-Friday (default: false).
      # @param all_week [Boolean] DEPRECATED: Use weekdays_only instead.
      # @param show_date [Boolean] Display the date number or not.
      # rubocop:disable Metrics/ParameterLists -- backward compatibility requires all params
      def initialize(template: nil,
                     start_date: nil,
                     period: :month,
                     events: [],
                     start_attribute: :start_time,
                     end_attribute: :end_time,
                     weekdays_only: nil,
                     all_week: nil,
                     show_date: true,
                     **options)
        @template = template
        @start_date = normalize_date(start_date)
        @period = normalize_period(period)
        @events = events
        @start_attribute = start_attribute
        @end_attribute = end_attribute
        @weekdays_only = resolve_weekdays_only(weekdays_only, all_week)
        @show_date = show_date
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      # @return [Array<Date>] All dates to display in the calendar
      def date_range
        @date_range ||= case period
                        when :month then month_date_range
                        when :week then start_date.all_week.to_a
                        else [start_date]
                        end
      end

      # @return [String] CSS classes for a week row
      def tr_classes_for(week)
        class_names(
          'week',
          'current-week': week.include?(Date.current)
        )
      end

      # @return [String] CSS classes for a day cell
      def td_classes_for(day)
        class_names(
          'day',
          today: today?(day),
          'start-date': day == start_date,
          'prev-month': previous_month?(day),
          'next-month': next_month?(day)
        )
      end

      # @return [Hash<Date, Array>] Events grouped by date
      def sorted_events
        @sorted_events ||= EventGrouper.new(
          @events,
          start_method: @start_attribute,
          end_method: @end_attribute
        ).by_date
      end

      # @return [Array<Date>] Filtered days based on weekdays_only setting
      def filter_week(week)
        show_weekends? ? week : week.select(&:on_weekday?)
      end

      # @return [Hash] Parameters for previous day navigation
      def prev_day
        date = start_date
        date = date.monday? && weekdays_only? ? date.prev_occurring(:friday) : date - 1.day
        { start_attribute => date }
      end

      # @return [Hash] Parameters for next day navigation
      def next_day
        date = start_date
        date = date.friday? && weekdays_only? ? date.next_occurring(:monday) : date + 1.day
        { start_attribute => date }
      end

      # View helper methods
      def month_view?
        period == :month
      end

      def week_view?
        period == :week
      end

      def show_weekends?
        !@weekdays_only
      end

      def weekdays_only?
        @weekdays_only
      end

      # DEPRECATED: Use weekdays_only? or show_weekends? instead
      # Kept for backward compatibility with existing templates
      # rubocop:disable Naming/PredicateMethod -- backward compatibility
      def all_week
        !@weekdays_only
      end
      # rubocop:enable Naming/PredicateMethod

      # Number of days to show in header (5 for weekdays, 7 for full week)
      def header_day_count
        show_weekends? ? 7 : 5
      end

      # @return [String, nil] Custom class for weekly title from options
      def weekly_title_class
        @options[:weekly_title_class]
      end

      # @return [String] CSS classes for date display
      def date_display_classes
        class_names(
          month_view? ? 'font-semibold float-right text-lg' : 'text-2xl font-bold',
          weekly_title_class
        )
      end

      private

      def normalize_date(date)
        return Date.current if date.blank?

        date.is_a?(Date) ? date : Date.parse(date.to_s)
      end

      def normalize_period(period)
        period_sym = (period || :month).to_sym
        PERIODS.include?(period_sym) ? period_sym : :month
      end

      # Handles backward compatibility: weekdays_only takes precedence,
      # falls back to inverting all_week, defaults to false (show full week)
      def resolve_weekdays_only(weekdays_only, all_week)
        return weekdays_only unless weekdays_only.nil?
        return !all_week unless all_week.nil?

        false # Default: show full week (weekdays_only: false)
      end

      def month_date_range
        (start_date.beginning_of_month.beginning_of_week..start_date.end_of_month.end_of_week).to_a
      end

      def today?(day)
        Date.current == day
      end

      def previous_month?(day)
        start_date.month != day.month && day < start_date
      end

      def next_month?(day)
        start_date.month != day.month && day > start_date
      end
    end

    # Handles grouping events by date, supporting multi-day events
    class EventGrouper
      def initialize(events, start_method: :start_time, end_method: :end_time)
        @events = events || []
        @start_method = start_method
        @end_method = end_method
      end

      # @return [Hash<Date, Array>] Events indexed by date
      def by_date
        @by_date ||= build_date_index
      end

      private

      def build_date_index
        index = Hash.new { |h, k| h[k] = [] }

        valid_events.sort_by { |e| e.public_send(@start_method) }.each do |event|
          date_range_for(event).each { |date| index[date] << event }
        end

        index
      end

      def valid_events
        @events.reject { |e| e.public_send(@start_method).nil? }
      end

      def date_range_for(event)
        event_start = event.public_send(@start_method).to_date
        event_end = event_end_date(event, event_start)
        (event_start..event_end)
      end

      def event_end_date(event, fallback)
        return fallback unless event.respond_to?(@end_method)

        event.public_send(@end_method)&.to_date || fallback
      end
    end
  end
end
