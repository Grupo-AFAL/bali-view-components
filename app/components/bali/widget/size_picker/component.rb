# frozen_string_literal: true

module Bali
  module Widget
    module SizePicker
      # The four-size chooser on a widget card's edit shelf.
      #
      #   render Bali::Widget::SizePicker::Component.new(size: :medium, title: "Low stock")
      #
      # Its own component because none of it is about showing a fact at four
      # canvases: it is a roving-tabindex ARIA radiogroup that draws each size as
      # a lattice, and it kept three constants and a helper inside the card that
      # the card never used for anything else.
      #
      # A REAL radiogroup, not a toggle group — the four sizes are mutually
      # exclusive, which is what the role exists for. It earns the role by
      # honouring the whole pattern: one tab stop for the set, arrows to move
      # within it, and selection following focus. Announcing radiogroup semantics
      # without the keyboard behaviour assistive tech then expects is worse than
      # an honest toggle group, which is what this used to be.
      #
      # The keyboard half lives in `WidgetGridController#sizeKeydown` — the card
      # is not the thing that moves, so the grid owns the gesture.
      class Component < ApplicationViewComponent
        # Which of the 4x2 lattice cells each size fills, in the grid's own
        # reading order: left to right, top row then bottom.
        #
        # The LATTICE is the point, not the fill. Four rectangles floating in
        # whitespace are four masses with no shared origin — which is why
        # `medium` (2x1) and `large` (2x2), being the same WIDTH, were
        # indistinguishable. The same four inside a visible 4x2 grid are a map.
        CELLS = {
          small: [ 0 ],
          medium: [ 0, 1 ],
          large: [ 0, 1, 4, 5 ],
          wide: [ 0, 1, 2, 3, 4, 5, 6, 7 ]
        }.freeze

        # The empty cell is a CONSTANT — `base-content`, never `current` —
        # because a frame of reference that changes with the state it frames is
        # not a reference. Deriving it from the button's text colour stacked two
        # opacities into 9% ink on white: invisible, which collapsed the map back
        # into the mass it replaced.
        CELL_FILLED = "rounded-[1px] bg-base-content/45 " \
                      "group-hover:bg-base-content/70 group-aria-checked:bg-primary"
        CELL_EMPTY = "rounded-[1px] bg-base-content/20 group-aria-checked:bg-primary/25"

        # Height and padding are separate dials and only one was the problem:
        # `btn-xs` shrinks both, overriding `--btn-p` takes the dead space and
        # leaves the click target alone.
        BUTTON_CLASSES = "group join-item btn btn-sm [--btn-p:.375rem] border-base-300 " \
                         "bg-base-100 hover:border-base-content/25 " \
                         "aria-checked:border-primary/40 aria-checked:bg-primary/10"

        # `title` names the widget being sized, so the group's accessible name
        # says WHICH card these four buttons belong to — a dashboard has twelve.
        def initialize(size:, title:)
          @size = size
          @title = title
          super()
        end

        private

        attr_reader :size, :title

        def sizes = Bali::Widget::SIZES

        def checked?(name) = name == size

        def cell_class(name, cell)
          CELLS.fetch(name).include?(cell) ? CELL_FILLED : CELL_EMPTY
        end
      end
    end
  end
end
