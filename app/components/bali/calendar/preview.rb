# frozen_string_literal: true

module Bali
  module Calendar
    class Preview < ApplicationViewComponentPreview
      # Interactive calendar preview
      # ---------------------------
      # Use the controls to explore different calendar configurations.
      #
      # @param period select { choices: [month, week] }
      # @param weekdays_only toggle "Show only Monday-Friday"
      # @param show_date toggle "Display day numbers"
      # @param with_events toggle "Display sample events"
      def default(period: :month, weekdays_only: false, show_date: true, with_events: false)
        events = with_events ? sample_events : []
        event_template = with_events ? 'bali/calendar/previews/template' : nil

        render(Calendar::Component.new(
                 start_date: Date.current,
                 period: period.to_sym,
                 weekdays_only: ActiveModel::Type::Boolean.new.cast(weekdays_only),
                 show_date: ActiveModel::Type::Boolean.new.cast(show_date),
                 events: events,
                 template: event_template
               )) do |c|
          c.with_header(route_path: '/lookbook')
        end
      end

      # Calendar with footer
      # --------------------
      # Demonstrates the footer slot for custom content below the calendar.
      def with_footer
        render(Calendar::Component.new(
                 start_date: Date.current,
                 weekdays_only: true,
                 period: :month,
                 show_date: true
               )) do |c|
          c.with_header(route_path: '/lookbook')
          c.with_footer do
            render(Bali::Tag::Component.new(text: 'Custom footer content', color: :primary))
          end
        end
      end

      # Calendar without navigation
      # ---------------------------
      # Shows calendar without the header navigation controls.
      # Useful when embedding in contexts where navigation is handled externally.
      def without_header
        render(Calendar::Component.new(
                 start_date: Date.current,
                 weekdays_only: true,
                 period: :month,
                 show_date: true
               ))
      end

      private

      def sample_events
        [
          Calendar::Previews::Event.new(start_time: Date.current, name: 'Today Event'),
          Calendar::Previews::Event.new(start_time: Date.current - 1.day, name: 'Yesterday'),
          Calendar::Previews::Event.new(start_time: Date.current + 2.days, name: 'Upcoming'),
          Calendar::Previews::Event.new(start_time: Date.current - 3.days, name: 'Past Event')
        ]
      end
    end
  end
end
