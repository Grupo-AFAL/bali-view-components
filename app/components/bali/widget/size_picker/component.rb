# frozen_string_literal: true

module Bali
  module Widget
    module SizePicker
      # The size chooser on a widget card's edit shelf.
      #
      #   render Bali::Widget::SizePicker::Component.new(size: :medium, title: "Low stock")
      #
      # Its own component because none of it is about showing a fact at three
      # canvases: it is a roving-tabindex ARIA radiogroup that draws each size as
      # a lattice, and it kept three constants and a helper inside the card that
      # the card never used for anything else.
      #
      # A REAL radiogroup — the sizes are mutually exclusive, which is what the
      # role exists for, and it earns the role by honouring the whole pattern: one
      # tab stop for the set, arrows within it, selection following focus.
      # Announcing radiogroup semantics without that keyboard behaviour is worse
      # than an honest toggle group.
      #
      # The keyboard half lives in `WidgetGridController#sizeKeydown` — the card
      # is not the thing that moves, so the grid owns the gesture.
      class Component < ApplicationViewComponent
        # Which of the 4x2 lattice cells each size fills, in the grid's own
        # reading order: left to right, top row then bottom.
        #
        # The LATTICE is the point, not the fill. Loose rectangles floating in
        # whitespace are masses with no shared origin — which is why
        # `medium` (2x1) and `large` (2x2), being the same WIDTH, were
        # indistinguishable. The same glyphs inside a visible 4x2 grid are a map.
        CELLS = {
          small: [ 0 ],
          medium: [ 0, 1 ],
          large: [ 0, 1, 4, 5 ]
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
        # says WHICH card these buttons belong to — a dashboard has twelve.
        #
        # `sizes` is what THIS widget offers, not the global vocabulary: a widget
        # with nothing to fill a `large` canvas should not invite a user to pick
        # one. Defaults to all of them.
        def initialize(size:, title:, sizes: Bali::Widget::SIZES)
          # COERCED. `checked?` compares with `==`, so a String size would match
          # nothing, no button would carry `tabindex="0"`, and the whole
          # radiogroup would drop out of the tab order — unreachable by keyboard,
          # silently. The card passes a symbol, but this is a public component
          # with its own preview, and the preview was already coercing on its
          # behalf, which is the tell that it belongs here.
          @size = size.to_sym
          @sizes = sizes
          @title = title
          super()
        end

        private

        attr_reader :size, :title, :sizes

        def checked?(name) = name == size

        def button_classes = BUTTON_CLASSES

        def cell_class(name, cell)
          CELLS.fetch(name).include?(cell) ? CELL_FILLED : CELL_EMPTY
        end
      end
    end
  end
end
