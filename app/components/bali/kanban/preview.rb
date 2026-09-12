# frozen_string_literal: true

module Bali
  module Kanban
    # @label Kanban
    # Kanban board built on top of SortableList, supporting drag-and-drop
    # between columns. Each column maps to a status value sent to the server on drop.
    #
    # ## Requirements
    # - SortableJS (loaded dynamically by SortableList)
    # - Stimulus controller `sortable-list`
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # A basic Kanban board with three status columns.
      # Drag cards between columns to reorder.
      def default
        render_with_template
      end

      # @label With Custom Colors
      # Each column can use a different DaisyUI badge color for its header indicator.
      def with_colors
        render_with_template
      end

      # @label With Footer
      # Columns accept an optional `footer` slot rendered after the card list —
      # the classic "+ add card" action. The footer lives outside the
      # SortableList, so it is never draggable and doesn't interfere with
      # dragging cards between columns.
      def with_footer
        render_with_template
      end

      # @label Scrollable Board
      # A real board: `layout: :flow` lays all columns on one horizontally
      # scrolling row (the `:grid` default caps at 4), and `height: :viewport`
      # caps the board to the visible viewport so each column's card list
      # scrolls internally instead of stretching the page.
      #
      # The `:viewport` height is `calc(100vh - var(--bali-kanban-offset, 17rem))`
      # — override `--bali-kanban-offset` on any ancestor to match your app's
      # header chrome.
      #
      # The empty column keeps a visible drop area (dashed border) driven by
      # CSS `:has()`, so it reacts live: drag the last card out of a column and
      # the affordance appears; hover a drag over the empty column and it
      # yields to SortableJS's preview.
      #
      # "Blocked" is rendered with `disabled: true`, so its cards cannot be
      # dragged out.
      def scrollable_board
        render_with_template
      end
    end
  end
end
