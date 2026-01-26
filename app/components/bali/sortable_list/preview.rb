# frozen_string_literal: true

module Bali
  module SortableList
    # @label SortableList
    # Drag-and-drop sortable list using SortableJS via Stimulus.
    # Supports nested lists, drag handles, and cross-list item movement.
    #
    # ## Requirements
    # - SortableJS library (loaded dynamically)
    # - Stimulus controller `sortable-list`
    #
    # ## Server Integration
    # When an item is dropped, a PATCH request is sent to the item's `update_url` with:
    # - `position` (or custom `position_param_name`) - new 1-indexed position
    # - `list_id` (or custom `list_param_name`) - target list identifier (for cross-list moves)
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Basic sortable list - drag items to reorder.
      # @param disabled toggle "Disable dragging"
      def default(disabled: false)
        render SortableList::Component.new(disabled: disabled) do |s|
          5.times do |i|
            s.with_item(update_url: '/sortable_list') { "Item #{i + 1}" }
          end
        end
      end

      # @label With Handle
      # Restrict dragging to a specific handle element.
      # Only the `:::` handle can initiate drag.
      # @param disabled toggle "Disable dragging"
      def with_handle(disabled: false)
        render_with_template(
          template: 'bali/sortable_list/previews/with_handle',
          locals: {
            disabled: disabled,
            handle: '.handle',
            handle_class: 'handle',
            update_url: '/sortable_list'
          }
        )
      end

      # @label Shared Lists
      # Two lists in the same group - items can be dragged between them.
      # Uses `group_name` to link lists and `list_id` to identify targets.
      # @param disabled toggle "Disable dragging"
      def shared(disabled: false)
        render_with_template(
          template: 'bali/sortable_list/previews/shared',
          locals: {
            disabled: disabled,
            group_name: 'shared',
            update_url: '/sortable_list'
          }
        )
      end

      # @label Nested Lists
      # Hierarchical structure with items containing sub-lists.
      # Useful for tree-like data (categories, folders, etc.).
      # @param disabled toggle "Disable dragging"
      def nested(disabled: false)
        render_with_template(
          template: 'bali/sortable_list/previews/nested',
          locals: {
            disabled: disabled,
            group_name: 'nested',
            update_url: '/sortable_list'
          }
        )
      end
    end
  end
end
