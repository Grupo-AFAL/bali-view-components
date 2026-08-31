# frozen_string_literal: true

module Bali
  module Widget
    module Card
      # THE BODY OF A CARD, and the base every widget type's card inherits.
      #
      # `Bali::Widget::Component` is the shell — the section, its drag and resize
      # contract, the edit chrome, and the degraded tile. Everything inside that
      # is here, and everything TYPE-SPECIFIC is in a subclass:
      #
      #   Widget::Value      a figure
      #   Widget::List       a figure, and rows beneath it
      #   Widget::Trend      a figure, its movement, and a chart
      #   Widget::Progress   a ring, and a chart
      #   Widget::Check      a pass/fail icon and its label
      #
      # THE THREE REGIONS, which every card has and each subclass fills what it
      # has:
      #
      #   headline — the fact. Required; a card without one is not a card.
      #   context  — how the fact is moving. A chart, or nothing.
      #   detail   — the breakdown. Rows, a slot, an empty message, or nothing.
      #
      # A subclass declares its regions by overriding `headline`, `context?` and
      # `detail_content`. The ARRANGEMENT of them — hero at `small`, side by side
      # at `medium`, stacked at `large` — is here, because it is the same for
      # every type and getting it wrong is a layout bug rather than a data one.
      class Component < ApplicationViewComponent
        # HOW MANY ROWS EACH CANVAS FITS — the only thing a size says that the size
        # itself does not, and a MEASUREMENT against Bali's own type sizes:
        #
        #   small   a ~215px tile fits one fact and nothing else
        #   medium  fact on the left, three rows or a sparkline on the right
        #   large   fact in a header band, chart under it, seven rows below
        #
        # Truncation lives here rather than in the widget: the widget answers which
        # rows matter, the card answers how many fit.
        #
        # Override per host through `Card::Component.rows_budget`, which is where
        # it is read.
        ROWS = { small: 0, medium: 3, large: 7 }.freeze

        # OVERRIDABLE, because a host with a larger base font or a denser theme
        # gets clipping and, as a frozen constant, no way to say so:
        #
        #   Bali::Widget::Card::Component.rows_budget =
        #     Bali::Widget::Card::Component::ROWS.merge(large: 5)
        # `instance_writer: false` for the reason `Bali::Widget::Base` gives: a
        # generated instance writer silently shadows the class value for one
        # object.
        class_attribute :rows_budget, default: ROWS, instance_writer: false

        def initialize(widget, size:)
          @widget = widget
          @size = size
          super()
        end

        private

        attr_reader :widget, :size

        delegate :key, :title, :short_title, :empty_message, :view_all_path, to: :widget

        # ---- what a subclass fills ------------------------------------------

        # THE FACT. Every subclass overrides this; there is no sensible default,
        # and a card that inherited one would render someone else's headline.
        def headline
          raise NotImplementedError, "#{self.class.name} must define `#headline`."
        end

        # Whether this card draws a chart. Only the charted types say yes, and
        # only where the canvas has room — a `small` tile has none.
        def context? = false

        # What sits under the headline on the HERO, beneath its label — the one
        # place a type adds to the hero. Only `Trend` uses it.
        def hero_footer = nil

        # THE CHART, or whatever else fills the context region. Only rendered
        # when `context?`.
        def context = nil

        # What goes in the breakdown region, or nil for nothing.
        def detail_content = nil

        # ---- the arrangement, shared ----------------------------------------

        # A hero is a DIFFERENT card, not a small one — no header, and the whole
        # tile is one link.
        def hero? = size == :small

        def stacked? = size == :large

        # A CHART IS AXIS-LESS below `large`: a sparkline is a chart that has
        # given up its axes, not a different component.
        def spark? = size == :medium

        def row_budget = self.class.rows_budget.fetch(size)

        def count = @count ||= widget.count

        # STRAIGHT OFF THE WIDGET. Both are on `Bali::Widget::Base`, so there is
        # nothing to ask `try` about and no place left for the card to guess what
        # kind of widget it is holding.
        # `defined?` for the same reason as `any?` below: a widget may declare
        # `display_value { nil }`, and `Check::Component` reads this three times
        # per hero card.
        def display_value
          return @display_value if defined?(@display_value)

          @display_value = widget.display_value
        end

        # `defined?` rather than `||=`: `any?` exists to answer false sometimes,
        # and `muted?`, `empty_state?` and `view_all_link?` all ask — so `||=`
        # would re-invoke the widget three times on exactly the cards where the
        # answer is interesting.
        def any?
          return @any if defined?(@any)

          @any = widget.any?
        end

        # A confident black zero and an all-clear zero look identical, so the
        # card dims the one that means nothing happened.
        def muted? = !any?

        def view_all_link? = any? && view_all_path.present?

        # Suppressed when a chart is already speaking for the card: "nothing to
        # show" beside a populated sparkline is a contradiction.
        def empty_state? = !any? && !context?

        # The detail region is rendered only when it HAS something. An empty
        # wrapper is not free: stacked it takes `flex-1` and squeezes the chart
        # into two fifths of a canvas it could have had whole, and inline it is a
        # blank right-hand column.
        def detail? = detail_content.present? || empty_state?

        # THE ONE METHOD that has to know about more than one region. `context?`
        # and `detail?` each decide whether their OWN region renders; this
        # decides how big one of them is GIVEN the other, which is why three bugs
        # of the same shape all ended here. Anything changing WHEN a region
        # renders has to be checked against this line.
        #
        # At `:inline` the chart divides a row with the headline, so it takes the
        # remaining width. Stacked it sits ABOVE the breakdown, and there an even
        # split starves the list and clips its last row; two fifths leaves the
        # rows whole — unless there is no breakdown, when it takes the canvas.
        def context_classes
          class_names(
            "bali-widget-context min-h-0 min-w-0 overflow-hidden",
            spark? || !detail? ? "flex-1" : "basis-2/5"
          )
        end
      end
    end
  end
end
