# frozen_string_literal: true

module Bali
  module Calendar
    module YearGrid
      class Component < ApplicationViewComponent
        # Keyed by Bali::Color::NAMES, spelled out: Tailwind only emits a class it
        # finds as a literal in a source file, so `"bg-#{name}"` compiles to nothing.
        #
        # The number stays `text-base-content` on the tint instead of taking the
        # colour like daisyUI's `badge-soft`: measured on the light themes, text in
        # the colour reads at 1.59:1 for `warning` and 1.68:1 for `accent`;
        # base-content on the same 20% tint is 9.25:1 at worst (AA wants 4.5).
        DAY_COLORS = {
          neutral: "bg-neutral/20 text-base-content hover:bg-neutral hover:text-neutral-content",
          primary: "bg-primary/20 text-base-content hover:bg-primary hover:text-primary-content",
          secondary: "bg-secondary/20 text-base-content hover:bg-secondary hover:text-secondary-content",
          accent: "bg-accent/20 text-base-content hover:bg-accent hover:text-accent-content",
          info: "bg-info/20 text-base-content hover:bg-info hover:text-info-content",
          success: "bg-success/20 text-base-content hover:bg-success hover:text-success-content",
          warning: "bg-warning/20 text-base-content hover:bg-warning hover:text-warning-content",
          error: "bg-error/20 text-base-content hover:bg-error hover:text-error-content",
          ghost: "bg-base-300/50 text-base-content hover:bg-base-300"
        }.freeze

        NEUTRAL_HIGHLIGHT = "bg-base-content/20 text-base-content hover:bg-base-content hover:text-base-100"

        # `/70`, not `/40`: composited over the ground, `/40` read 2.36:1 on `afal`
        # at 11px; `/70` is 5.54:1 there, the worst of the five themes (AA wants 4.5).
        # The tint on a day with events is what codes the map, not this number.
        EMPTY_DAY = "text-base-content/70"

        DAY_CLASSES = "year-day relative flex items-center justify-center " \
                      "aspect-square rounded-sm text-[0.6875rem] leading-none"

        # `auto-fit` against the CONTAINER, not a `sm:`/`lg:`/`xl:` ramp against the
        # viewport: measured at 1440px with the calendar in a 400px drawer, the ramp
        # drew 4 columns of 76px with 9px day cells. `min(Xrem, 100%)` keeps the
        # track from overflowing a container narrower than its minimum. No track
        # maximum either: `auto-fit` counts columns against a definite max, and
        # `minmax(20rem, 22rem)` drops `:md` at 1440px from 4 columns to 3.
        MONTH_SIZES = {
          xs: "grid-cols-[repeat(auto-fit,minmax(min(10rem,100%),1fr))]",
          sm: "grid-cols-[repeat(auto-fit,minmax(min(14rem,100%),1fr))]",
          md: "grid-cols-[repeat(auto-fit,minmax(min(20rem,100%),1fr))]",
          lg: "grid-cols-[repeat(auto-fit,minmax(min(26rem,100%),1fr))]",
          xl: "grid-cols-[repeat(auto-fit,minmax(min(34rem,100%),1fr))]"
        }.freeze

        # `date.abbr_day_names` is indexed by wday (0 = Sunday); the initials are
        # rotated to `Date.beginning_of_week`, which is where the rows start.
        WDAYS = %i[sunday monday tuesday wednesday thursday friday saturday].freeze

        # @param start_date [Date] Any date in the year to draw.
        # @param events_by_date [Hash<Date, Array>] Already grouped by the parent.
        # @param template [String, nil] Host partial rendered inside the hover card.
        # @param show_date [Boolean] Draw the day number inside each cell.
        # @param day_url [Proc, nil] `->(day, events) { url }`. nil, or a nil return,
        #   leaves the day unlinked.
        # @param day_variant [Proc, nil] `->(day, events) { :success }`, a name from
        #   Bali::Color::NAMES. nil falls back to a neutral highlight.
        # @param month_summary [Proc, nil] `->(month, events) { "11" }`, drawn beside
        #   the month name. Receives the first day of the month and that month's events.
        # @param month_size [Symbol] Size of one miniature month: :xs, :sm, :md, :lg,
        #   :xl — :xs fits many per row, :xl few. The container decides the count.
        # rubocop:disable Metrics/ParameterLists
        def initialize(start_date:, events_by_date: {}, template: nil, show_date: true,
                       day_url: nil, day_variant: nil, month_summary: nil, month_size: :md)
          # rubocop:enable Metrics/ParameterLists
          @start_date = start_date
          @events_by_date = events_by_date
          @template = template
          @show_date = show_date
          @day_url = day_url
          @day_variant = day_variant
          @month_summary = month_summary
          @month_size_class = month_size_class!(month_size)
        end

        attr_reader :start_date, :template, :show_date, :month_size_class

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

        # @return [Array<Date, nil>] The month's days padded with nil to whole weeks —
        #   not the neighbouring month's dates, which a year grid would draw twice.
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

        # `uniq`: a multi-day event is indexed under every date it spans.
        def events_in(month)
          (month.beginning_of_month..month.end_of_month)
            .flat_map { |day| events_on(day) }
            .uniq
        end

        # The three lambdas run while this grid renders, and for that whole time
        # ViewComponent points the host view's `@virtual_path` at this component: a
        # lazy `t('.x')` inside them resolves to `bali_view.calendar.year_grid.x`.
        def month_summary_for(month)
          @month_summary&.call(month, events_in(month))
        end

        def day_url_for(day)
          @day_url&.call(day, events_on(day))
        end

        # The hovercard controller mounts its tippy in `connect()`, so a card on every
        # cell costs 365 instances (measured: 36 against 365, 118 KB against 311 KB of HTML).
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

        # Not `l(day, format: :long)`: the gem ships no date formats and cannot
        # assume the host's.
        def day_label(day)
          "#{day.day} #{month_name(day)} #{day.year}"
        end

        # `<time datetime>` and not an `aria-label` on the unlinked cell: a bare
        # <span> maps to the `generic` role, which ARIA does not name. The cell that
        # carries a hover card is the exception: the card opens on `focusin`, so
        # without a tab stop its events only exist for the mouse (WCAG 2.1.1), and
        # a focus stop is announced, so it gets the full date like the linked cell.
        def day_cell(day)
          url = day_url_for(day)
          number = day.day.to_s if show_date

          if url.present?
            render Bali::Link::Component.new(
              href: url, name: number, plain: true,
              class: day_classes(day), aria: { label: day_label(day) }
            )
          elsif hover?(day)
            tag.time(number, class: day_classes(day), datetime: day.iso8601,
                             tabindex: 0, aria: { label: day_label(day) })
          else
            tag.time(number, class: day_classes(day), datetime: day.iso8601)
          end
        end

        private

        # Raises, unlike `normalize_period`: `month_size:` is written in code, never
        # read off a query string.
        def month_size_class!(size)
          MONTH_SIZES.fetch(size&.to_sym) do
            raise ArgumentError,
                  "#{self.class}: unknown month_size #{size.inspect}. " \
                  "Valid: #{MONTH_SIZES.keys.map(&:inspect).join(', ')}."
          end
        end

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
