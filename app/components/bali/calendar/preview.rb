# frozen_string_literal: true

module Bali
  module Calendar
    # Sibling constants in full — `Bali::Calendar::Component`: Lookbook keeps this
    # class across a `reload!`, so a short form resolves against a namespace
    # Zeitwerk already discarded (#843).
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
      # Twelve miniature months. The three lambdas are optional; turn them off to
      # see the bare on/off map. Resize the pane: the month count follows the container.
      #
      # @param start_date text "Any date in the year to draw"
      # @param month_size select { choices: [xs, sm, md, lg, xl] }
      # @param show_date toggle "Display day numbers"
      # @param weekdays_only toggle "Ignored by the year view — the grid stays at seven columns"
      # @param with_events toggle "Display sample events (and their hover cards)"
      # @param with_day_url toggle "Make days with events navigate somewhere"
      # @param with_day_variant toggle "Colour each day from its events"
      # @param with_month_summary toggle "Label each month with its event count"
      # @param bounded toggle "Limit navigation to the drawn year: both arrows go disabled"
      # rubocop:disable Metrics/ParameterLists
      def year(start_date: nil, month_size: :md, show_date: true, weekdays_only: false,
               with_events: true, with_day_url: true, with_day_variant: true,
               with_month_summary: true, bounded: false)
        # rubocop:enable Metrics/ParameterLists
        with_events = ActiveModel::Type::Boolean.new.cast(with_events)
        bounded = ActiveModel::Type::Boolean.new.cast(bounded)
        first_day = (start_date.presence || Date.current).to_date.beginning_of_year

        render(Bali::Calendar::Component.new(
                 start_date: first_day,
                 period: :year,
                 month_size: month_size,
                 weekdays_only: ActiveModel::Type::Boolean.new.cast(weekdays_only),
                 show_date: ActiveModel::Type::Boolean.new.cast(show_date),
                 events: with_events ? year_sample_events(first_day.year) : [],
                 template: with_events ? 'bali/calendar/previews/template' : nil,
                 day_url: (day_url_lambda if ActiveModel::Type::Boolean.new.cast(with_day_url)),
                 day_variant: (day_variant_lambda if ActiveModel::Type::Boolean.new.cast(with_day_variant)),
                 month_summary: (month_summary_lambda if ActiveModel::Type::Boolean.new.cast(with_month_summary))
               )) do |c|
          c.with_header(route_path: '/lookbook', period_switch: %i[month year],
                        min_date: (first_day if bounded), max_date: (first_day.end_of_year if bounded))
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

      # One long name: the month view's `table-fixed` cell is the narrowest place
      # the partial renders.
      def sample_events
        [
          build_event(Date.current, 'Today Event', nil),
          build_event(Date.current - 1.day, 'Yesterday', nil),
          build_event(Date.current + 2.days, 'Upcoming, with a deliberately long name that wraps onto several lines', nil),
          build_event(Date.current - 3.days, 'Past Event', nil)
        ]
      end

      # The 11th holds two events (`has-multiple`) and a name long enough to wrap
      # in a hover card tippy caps at 350px. Keep both. `ghost` is in the cycle so a
      # ghost day is drawn: base-surface-steps.cy.js measures 20 January.
      def year_sample_events(year)
        (1..12).flat_map do |month|
          first = Date.new(year, month, 1)
          statuses = %i[success warning error info ghost].rotate(month)

          [
            build_event(first + 4, "Item #{month}-A", statuses[0]),
            build_event(first + 11, "Item #{month}-B, with a deliberately long name that wraps onto several lines",
                        statuses[1]),
            build_event(first + 11, "Item #{month}-C", statuses[2]),
            build_event(first + 19, "Item #{month}-D", statuses[3])
          ]
        end
      end

      # `url` points at this preview: the only route the gem can be sure exists.
      def build_event(date, name, status)
        Bali::Calendar::Previews::Event.new(
          start_time: date, name: name, status: status,
          url: "/lookbook/preview/bali/calendar/default?start_date=#{date}"
        )
      end

      def day_url_lambda
        lambda do |day, events|
          next if events.empty?

          "/lookbook/preview/bali/calendar/default?period=month&with_events=true" \
            "&start_date=#{day}"
        end
      end

      def day_variant_lambda
        ->(_day, events) { events.first&.status }
      end

      def month_summary_lambda
        ->(_month, events) { events.size.to_s }
      end
    end
  end
end
