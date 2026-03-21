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
    end
  end
end
