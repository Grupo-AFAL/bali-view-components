# frozen_string_literal: true

module Bali
  module Calendar
    # Sibling constants are written in full — `Bali::Calendar::Component`, never
    # `Calendar::Component`. `Module.nesting` is captured at parse time and holds
    # the module OBJECT, and Lookbook keeps this class in its own registry across
    # a `reload!`, so a short form resolves against a namespace Zeitwerk has
    # already discarded (#843).
    class Preview < ApplicationViewComponentPreview
      # Interactive calendar preview
      # ---------------------------
      # Use the controls to explore different calendar configurations.
      #
      # @param period select { choices: [month, week] }
      # @param start_date text "Any string; unparseable input falls back to today"
      # @param weekdays_only toggle "Show only Monday-Friday"
      # @param show_date toggle "Display day numbers"
      # @param with_events toggle "Display sample events"
      def default(period: :month, start_date: nil, weekdays_only: false, show_date: true,
                  with_events: false)
        events = with_events ? sample_events : []
        event_template = with_events ? 'bali/calendar/previews/template' : nil

        render(Bali::Calendar::Component.new(
                 start_date: start_date,
                 period: period,
                 weekdays_only: ActiveModel::Type::Boolean.new.cast(weekdays_only),
                 show_date: ActiveModel::Type::Boolean.new.cast(show_date),
                 events: events,
                 template: event_template
               )) do |c|
          c.with_header(route_path: '/lookbook')
        end
      end

      # Year view
      # ---------
      # Twelve miniature months as a density map: a day with nothing on it is
      # dimmed, a day with events takes the colour the HOST returns from
      # `day_variant`, and a day holding more than one event also gets the
      # `has-multiple` dot. `weekdays_only` is ignored here on purpose — a map
      # that hides Saturdays hides events.
      #
      # The three lambdas are all optional; turn them off to see the grid with
      # nothing but the on/off signal.
      #
      # `month_size` names the size of the MONTH, not of the view: `xs` fits many
      # small months per row, `xl` few large ones. Resize the preview pane and the
      # count follows the container, with no breakpoint involved.
      #
      # @param start_date text "Any date in the year to draw"
      # @param month_size select { choices: [xs, sm, md, lg, xl] }
      # @param show_date toggle "Display day numbers"
      # @param weekdays_only toggle "Ignored by the year view — the grid stays at seven columns"
      # @param with_events toggle "Display sample events (and their hover cards)"
      # @param with_day_url toggle "Make days with events navigate somewhere"
      # @param with_day_variant toggle "Colour each day from its events"
      # @param with_month_summary toggle "Label each month with its event count"
      # rubocop:disable Metrics/ParameterLists
      def year(start_date: nil, month_size: :md, show_date: true, weekdays_only: false,
               with_events: true, with_day_url: true, with_day_variant: true,
               with_month_summary: true)
        # rubocop:enable Metrics/ParameterLists
        with_events = ActiveModel::Type::Boolean.new.cast(with_events)

        render(Bali::Calendar::Component.new(
                 start_date: start_date || Date.current.beginning_of_year,
                 period: :year,
                 month_size: month_size,
                 weekdays_only: ActiveModel::Type::Boolean.new.cast(weekdays_only),
                 show_date: ActiveModel::Type::Boolean.new.cast(show_date),
                 events: with_events ? year_sample_events : [],
                 template: with_events ? 'bali/calendar/previews/template' : nil,
                 day_url: (day_url_lambda if ActiveModel::Type::Boolean.new.cast(with_day_url)),
                 day_variant: (day_variant_lambda if ActiveModel::Type::Boolean.new.cast(with_day_variant)),
                 month_summary: (month_summary_lambda if ActiveModel::Type::Boolean.new.cast(with_month_summary))
               )) do |c|
          c.with_header(route_path: '/lookbook', period_switch: %i[month year])
        end
      end

      # Calendar with footer
      # --------------------
      # Demonstrates the footer slot for custom content below the calendar.
      def with_footer
        render(Bali::Calendar::Component.new(
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
        render(Bali::Calendar::Component.new(
                 start_date: Date.current,
                 weekdays_only: true,
                 period: :month,
                 show_date: true
               ))
      end

      private

      def sample_events
        [
          Bali::Calendar::Previews::Event.new(start_time: Date.current, name: 'Today Event'),
          Bali::Calendar::Previews::Event.new(start_time: Date.current - 1.day, name: 'Yesterday'),
          Bali::Calendar::Previews::Event.new(start_time: Date.current + 2.days, name: 'Upcoming'),
          Bali::Calendar::Previews::Event.new(start_time: Date.current - 3.days, name: 'Past Event')
        ]
      end

      # Scattered across the whole year so the grid has something to show in every
      # month, with a few days deliberately holding two events of different status —
      # that is the case `has-multiple` exists for.
      def year_sample_events
        year = Date.current.year
        statuses = %i[success warning error info]

        (1..12).flat_map do |month|
          first = Date.new(year, month, 1)

          [
            build_event(first + 4, "Item #{month}-A", statuses[month % 4]),
            build_event(first + 11, "Item #{month}-B", statuses[(month + 1) % 4]),
            build_event(first + 11, "Item #{month}-C", statuses[(month + 2) % 4]),
            build_event(first + 19, "Item #{month}-D", statuses[(month + 3) % 4])
          ]
        end
      end

      def build_event(date, name, status)
        Bali::Calendar::Previews::Event.new(start_time: date, name: name, status: status)
      end

      # A day is a link only where there is something to open — the nil return is
      # as much a part of the contract as the URL. Here it opens that day's month,
      # which is the shape of the drill-down a host usually wants.
      def day_url_lambda
        lambda do |day, events|
          next if events.empty?

          "/lookbook/preview/bali/calendar/default?period=month&with_events=true" \
            "&start_date=#{day}"
        end
      end

      # The host decides which of its own states wins when a day holds several —
      # here, simply the first event's. The component never guesses that order.
      def day_variant_lambda
        ->(_day, events) { events.first&.status }
      end

      def month_summary_lambda
        ->(_month, events) { events.size.to_s }
      end
    end
  end
end
