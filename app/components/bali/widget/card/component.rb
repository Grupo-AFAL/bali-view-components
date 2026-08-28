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
        # `region` rather than `size`: the card is handed what its canvas has
        # room for and never re-derives it, so `REGIONS` stays the one place a
        # size's shape is written down.
        def initialize(widget, region:)
          @widget = widget
          @region = region
          super()
        end

        private

        attr_reader :widget, :region

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

        def hero? = region.fetch(:layout) == :hero

        def stacked? = region.fetch(:layout) == :stacked

        # A CHART IS AXIS-LESS below `large`: a sparkline is a chart that has
        # given up its axes, not a different component.
        def spark? = region.fetch(:context) == :spark

        def rows_budget = region.fetch(:rows)

        # THE COUNT, which is really "does this widget have anything" — it drives
        # the empty state, the headline dimming and the "view all" label. Every
        # pattern answers it.
        def count = @count ||= widget.count

        # WHAT THE HEADLINE PRINTS. A type whose headline is not its count says
        # so — `ValueBase` through its `display_value` declaration, `CheckBase`
        # with its pass/fail label — and the rest get the abbreviated count,
        # since a ~215px tile at `text-4xl` fits four to six characters.
        def display_value = @display_value ||= widget.try(:display_value) || Bali::Widget.abbreviate(count)

        def any? = count.positive?

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
        #
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
