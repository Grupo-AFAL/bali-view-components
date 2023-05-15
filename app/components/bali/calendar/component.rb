# frozen_string_literal: true

module Bali
  module Calendar
    class Component < ApplicationViewComponent
      attr_reader :start_date, :period, :start_attribute, :end_attribute, :events,
                  :template, :all_week, :show_date

      renders_one :footer
      renders_one :header, ->(route_path: nil, period_switch: true, **options) do
                             Header::Component.new(start_date: @start_date.to_s,
                                                   period: @period,
                                                   route_path: route_path,
                                                   period_switch: period_switch,
                                                   start_attribute: @start_attribute,
                                                   **options)
                           end
      # @param template [String] Path to an HTML template with the content of each day.
      # @param start_date [Date|String] The date to start the calendar from.
      # @param period [Symbol] The period of the calendar, :month or :week.
      # @param events [Array] Events to display in the calendar, must respond to the method
      #  defined as `start_attribute`.
      # @param start_attribute [Symbol] Method to be called on each event object for the
      #  start_date.
      # @param end_attribute [Symbol] Method to be called on each event object for the end date.
      # @param all_week [Boolean] Display the entire week or just the weekdays.
      # @param show_date [Boolean] Display the date or not.

      # rubocop:disable Metrics/ParameterLists
      def initialize(template: nil,
                     start_date: Date.current.to_s,
                     period: :month,
                     events: [],
                     start_attribute: :start_time,
                     end_attribute: :end_time,
                     all_week: true,
                     show_date: true,
                     **options)
        @template = template
        @start_date = Date.parse(start_date.presence || Date.current.to_s)
        @period = (period || :month).to_sym
        @events = events
        @start_attribute = start_attribute
        @end_attribute = end_attribute
        @all_week = all_week
        @show_date = show_date
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      def date_range
        if period == :month
          (start_date.beginning_of_month.beginning_of_week..start_date.end_of_month.end_of_week)
            .to_a
        else
          start_date.all_week.to_a
        end
      end

      def tr_classes_for(week)
        tr_class = ['week']
        tr_class << 'current-week' if week.include?(Date.current)

        tr_class
      end

      def td_classes_for(day)
        td_class = ['day']
        td_class << 'today' if Date.current == day
        td_class << 'start-date' if day == start_date
        td_class << 'prev-month' if start_date.month != day.month && day < start_date
        td_class << 'next-month' if start_date.month != day.month && day > start_date

        td_class
      end

      def sorted_events
        @sorted_events ||= begin
          events = @events.reject { |e| e.send(start_attribute).nil? }.sort_by(&start_attribute)
          group_events_by_date(events)
        end
      end

      def group_events_by_date(events)
        events_grouped_by_date = Hash.new { |h, k| h[k] = [] }

        events.each do |event|
          event_start_date = event.send(start_attribute).to_date
          event_end_date = if event.respond_to?(end_attribute) && event.send(end_attribute).present?
                             event.send(end_attribute).to_date
                           else
                             event_start_date
                           end
          (event_start_date..event_end_date.to_date).each do |enumerated_date|
            events_grouped_by_date[enumerated_date] << event
          end
        end

        events_grouped_by_date
      end

      def filter_week(week)
        return week if all_week

        week.select(&:on_weekday?)
      end

      def prev_day
        date = start_date
        if date.monday? && !all_week
          date = date.prev_occurring(:friday)
        else
          date -= 1.day
        end

        { start_attribute => date }
      end

      def next_day
        date = start_date
        if date.friday? && !all_week
          date = date.next_occurring(:monday)
        else
          date += 1.day
        end

        { start_attribute => date }
      end
    end
  end
end
