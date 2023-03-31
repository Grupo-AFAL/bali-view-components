# frozen_string_literal: true

module Bali
  module Calendar
    class Preview < ApplicationViewComponentPreview
      # Basic calendar
      # -------------
      def default
        render(Calendar::Component.new(
                 start_date: Date.current.to_s,
                 all_week: false,
                 show_date: true
               )) do |c|
          c.header(start_date: Date.current.to_s, route_path: '/lookbook')
        end
      end

      # Calendar with week view
      # ----------------------
      def week
        render(
          Calendar::Component.new(start_date: Date.current.to_s,
                                  all_week: false,
                                  period: :week,
                                  show_date: true)
        ) do |c|
          c.header(start_date: Date.current.to_s, route_path: '/lookbook')
        end
      end

      # Calendar without period options
      # ---------------------------
      # This will hide the month and week options.
      def without_period
        render(Calendar::Component.new(start_date: Date.current.to_s,
                                       all_week: false,
                                       period: :month,
                                       show_date: true)) do |c|
          c.header(start_date: Date.current.to_s, route_path: '/lookbook', period_switch: false)
        end
      end

      # Calendar without date
      # -------------------
      # This will hide the day date.
      def without_date
        render(Calendar::Component.new(start_date: Date.current.to_s,
                                       all_week: false,
                                       period: :month,
                                       show_date: false)) do |c|
          c.header(start_date: Date.current.to_s, route_path: '/lookbook')
        end
      end

      # Calendar with all week
      # ---------------------
      # This will display the entire week.
      def all_week
        render(Calendar::Component.new(start_date: Date.current.to_s,
                                       all_week: true,
                                       period: :month,
                                       show_date: true)) do |c|
          c.header(start_date: Date.current.to_s, route_path: '/lookbook')
        end
      end

      # Calendar with events
      # -------------------
      # This will display the events in the calendar.
      def with_events
        events = [
          Calendar::Previews::Event.new(start_time: Date.current, name: 'Event 2'),
          Calendar::Previews::Event.new(start_time: Date.current - 1.day, name: 'Event 1')
        ]

        render(Calendar::Component.new(start_date: Date.current.to_s,
                                       all_week: false,
                                       period: :month,
                                       show_date: true,
                                       template: 'bali/calendar/previews/template',
                                       events: events)) do |c|
          c.header(start_date: Date.current.to_s, route_path: '/lookbook')
        end
      end

      # Calendar with footer
      # -------------------
      # This will display custom content in the footer.
      def with_footer
        render(Calendar::Component.new(start_date: Date.current.to_s,
                                       all_week: false,
                                       period: :month,
                                       show_date: true,
                                       footer: true)) do |c|
          c.header(start_date: Date.current.to_s, route_path: '/lookbook')
          c.footer do
            '<span class="tag is-primary">This is the footer<spam>'.html_safe
          end
        end
      end
    end
  end
end
