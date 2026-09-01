# frozen_string_literal: true

module Bali
  module Calendar
    module YearGrid
      # The twelve miniature months behind `Bali::Calendar::Component` with
      # `period: :year`. It is a density map, not a third grid: the question it
      # answers is "which days of this year have something on them", and every
      # word of meaning on top of that comes from the host through three
      # lambdas — `day_url`, `day_variant` and `month_summary`.
      #
      # ONE COLOUR PER DAY, PLUS A COUNT
      # --------------------------------
      # A day can hold events the host considers different in kind. The cell
      # still gets exactly one colour, the one `day_variant` returns, because
      # the host is the only party that knows which of its own states outranks
      # the others. What the component adds is `has-multiple`: a dot in the
      # corner saying "there is more than one thing here", and the full list
      # inside the hover card.
      #
      # A gradient across the cell was the alternative and it is worse. The cell
      # is roughly 20px on a phone; two colours in that space encode no order —
      # nothing tells the reader which half is "first" — and the blend between
      # them reads as a third state nobody defined. A dot says "more" and says
      # nothing else, which is the only thing the component actually knows.
      class Component < ApplicationViewComponent
        # Keyed by Bali::Color::NAMES. Spelled out, never interpolated: Tailwind
        # only emits a class it can find as a literal string in a source file, so
        # `"bg-#{name}"` compiles to nothing at all. See Bali::Color.
        DAY_COLORS = {
          neutral: "bg-neutral text-neutral-content",
          primary: "bg-primary text-primary-content",
          secondary: "bg-secondary text-secondary-content",
          accent: "bg-accent text-accent-content",
          info: "bg-info text-info-content",
          success: "bg-success text-success-content",
          warning: "bg-warning text-warning-content",
          error: "bg-error text-error-content",
          ghost: "bg-base-300 text-base-content"
        }.freeze

        # A day that has events but whose host named no colour for it. Still
        # visibly "on", because the map's whole job is on/off.
        NEUTRAL_HIGHLIGHT = "bg-base-content/20 text-base-content"

        # A day with nothing on it. Dimmed, never hidden: an empty day is data.
        EMPTY_DAY = "text-base-content/40"

        DAY_CLASSES = "year-day relative flex items-center justify-center " \
                      "aspect-square rounded-sm text-[0.6875rem] leading-none"

        # `date.abbr_day_names` is indexed by wday, so index 0 is Sunday. The
        # grid starts on whatever `Date.beginning_of_week` says, the same day the
        # month view's rows start on, so the initials are rotated to match rather
        # than assumed to begin on Monday.
        WDAYS = %i[sunday monday tuesday wednesday thursday friday saturday].freeze

        # @param start_date [Date] Any date in the year to draw.
        # @param events_by_date [Hash<Date, Array>] Already grouped by the parent.
        # @param template [String, nil] Host partial rendered inside the hover card.
        # @param show_date [Boolean] Draw the day number inside each cell.
        # @param day_url [Proc, nil] `->(day, events) { url }`. nil, or a nil return,
        #   leaves the day unlinked — the component invents no destination.
        # @param day_variant [Proc, nil] `->(day, events) { :success }`, a name from
        #   Bali::Color::NAMES. nil falls back to a neutral highlight.
        # @param month_summary [Proc, nil] `->(month, events) { "11" }`, drawn beside
        #   the month name. Receives the first day of the month and that MONTH's events.
        def initialize(start_date:, events_by_date: {}, template: nil, show_date: true,
                       day_url: nil, day_variant: nil, month_summary: nil)
          @start_date = start_date
          @events_by_date = events_by_date
          @template = template
          @show_date = show_date
          @day_url = day_url
          @day_variant = day_variant
          @month_summary = month_summary
        end

        attr_reader :start_date, :template, :show_date

        # @return [Array<Date>] The first day of each of the twelve months.
        def months
          @months ||= (1..12).map { |month| Date.new(start_date.year, month, 1) }
        end

        # @return [String] Localised month name. `date.month_names` is 1-indexed.
        def month_name(month)
          t("date.month_names")[month.month]
        end

        # @return [Array<String>] Weekday initials, rotated to the week's first day.
        def weekday_initials
          @weekday_initials ||= t("date.abbr_day_names").rotate(first_wday)
        end

        # @return [Array<Date, nil>] The month's days padded with nil to whole weeks.
        #   nil rather than the neighbouring month's dates: a day drawn twice in the
        #   same year is a day counted twice by the reader.
        def month_days(month)
          first = month.beginning_of_month
          last = month.end_of_month

          Array.new((first - first.beginning_of_week).to_i) +
            (first..last).to_a +
            Array.new((last.end_of_week - last).to_i)
        end

        # #fetch and not #[]: the parent's hash has a default block that writes the
        # key it was asked for, and reading 365 days would grow it by 365 entries.
        def events_on(day)
          @events_by_date.fetch(day, [])
        end

        # The events of a whole month, deduplicated: a multi-day event is indexed
        # under every date it spans.
        def events_in(month)
          (month.beginning_of_month..month.end_of_month)
            .flat_map { |day| events_on(day) }
            .uniq
        end

        def month_summary_for(month)
          @month_summary&.call(month, events_in(month))
        end

        def day_url_for(day)
          @day_url&.call(day, events_on(day))
        end

        # Tippy is mounted per hover card, so a year of empty cells would cost 365
        # instances to show 365 empty popups. Only the days that have something to
        # say get one.
        def hover?(day)
          template.present? && events_on(day).any?
        end

        def day_classes(day)
          events = events_on(day)

          class_names(
            DAY_CLASSES,
            day_color(day, events),
            "year-today" => day == Date.current,
            "has-multiple" => events.size > 1
          )
        end

        # Built from `date.month_names` rather than `l(day, format: :long)`: the
        # gem ships no date formats of its own, and the format a host has is not
        # something this component can assume.
        def day_label(day)
          "#{day.day} #{month_name(day)} #{day.year}"
        end

        # `aria-label` on the link and `<time>` on the rest, not `aria-label` on both:
        # a link takes an accessible name, a bare <span> maps to `generic` and ARIA
        # does not name those — the attribute would be there and do nothing. `<time
        # datetime>` is what actually carries the full date on a cell whose visible
        # text is a bare number.
        def day_cell(day)
          url = day_url_for(day)
          number = day.day.to_s if show_date

          if url.present?
            render Bali::Link::Component.new(
              href: url, name: number, plain: true,
              class: day_classes(day), aria: { label: day_label(day) }
            )
          else
            tag.time(number, class: day_classes(day), datetime: day.iso8601)
          end
        end

        private

        def first_wday
          WDAYS.index(Date.beginning_of_week) || 1
        end

        def day_color(day, events)
          return EMPTY_DAY if events.empty?

          DAY_COLORS.fetch(variant_for(day, events)) { NEUTRAL_HIGHLIGHT }
        end

        def variant_for(day, events)
          Bali::Color.name!(self.class, @day_variant&.call(day, events), param: :day_variant)
        end
      end
    end
  end
end
