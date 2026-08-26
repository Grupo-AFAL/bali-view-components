# frozen_string_literal: true

module Bali
  module Widget
    # The single entry point for rendering any dashboard widget:
    #
    #   render Bali::Widget::Component.new(widget)
    #
    # Takes the WIDGET, not its `Result` — the widget delegates count/items to
    # the result and still knows its own key, which is what lets one component
    # derive every widget's copy.
    #
    # Does no data access at all, which is what lets it be tested against plain
    # `Base` subclasses with a stubbed `#call`.
    class Component < ApplicationViewComponent
      # How many of the widget's `PREVIEW_ROWS` this card has room for.
      # Truncation lives HERE, not in `#call`: the widget answers "which rows
      # matter", the card answers "how many fit".
      #
      # `small` renders NO rows on purpose — a ~215px card with three truncated
      # titles is worse than the single number those rows summarise, so it shows
      # a stat instead. That is what "the design changes with the size" means.
      ROWS = { small: 0, medium: 3, large: 7, wide: 3 }.freeze

      # Which of the 4x2 lattice cells each size fills, in the grid's own reading
      # order: left to right, top row then bottom.
      #
      # The LATTICE is the point, not the fill. Four rectangles floating in
      # whitespace are four masses with no shared origin — which is why `medium`
      # (2x1) and `large` (2x2), being the same WIDTH, were indistinguishable.
      # The same four inside a visible 4x2 grid are a map.
      CELLS = {
        small: [ 0 ],
        medium: [ 0, 1 ],
        large: [ 0, 1, 4, 5 ],
        wide: [ 0, 1, 2, 3 ]
      }.freeze

      # The empty cell is a CONSTANT — `base-content`, never `current` — because
      # a frame of reference that changes with the state it frames is not a
      # reference. Deriving it from the button's text colour stacked two
      # opacities into 9% ink on white: invisible, which collapsed the map back
      # into the mass it replaced.
      CELL_FILLED = "rounded-[1px] bg-base-content/45 " \
                    "group-hover:bg-base-content/70 group-aria-pressed:bg-primary"
      CELL_EMPTY = "rounded-[1px] bg-base-content/20 group-aria-pressed:bg-primary/25"

      # Custom content for a widget that isn't a list. Replaces the shape enum
      # the source app used, which had to name an app concept (`:verdict`)
      # inside a library.
      renders_one :body

      delegate :key, :title, :short_title, :count, :items, :view_all_path,
               :empty_message, :size, :failed?, to: :widget

      # `**options` so a host can add a `data-testid`, an extra class, or a
      # Turbo frame attribute to a card — the same passthrough every other
      # component in this library offers on its root tag.
      def initialize(widget, **options)
        @widget = widget
        @options = options
        super()
      end

      def rows = items.first(ROWS.fetch(size))

      # The compact card: a count, a short label, and the whole tile is the link.
      def summary? = ROWS.fetch(size).zero?

      def any_items? = count.positive?

      def view_all_link? = any_items? && view_all_path.present?

      # Here rather than in the template so the template stops doing conditional
      # presentation with fully qualified constants on a 160-character line.
      def cell_class(name, cell)
        CELLS.fetch(name).include?(cell) ? CELL_FILLED : CELL_EMPTY
      end

      private

      attr_reader :widget, :options

      def card_classes
        class_names(
          "bali-widget-card",
          summary? ? "p-4" : "p-6",
          options[:class]
        )
      end

      def card_attributes
        options.except(:class)
      end
    end
  end
end
