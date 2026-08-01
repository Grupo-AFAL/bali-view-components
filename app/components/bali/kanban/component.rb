# frozen_string_literal: true

module Bali
  module Kanban
    class Component < ApplicationViewComponent
      # Tailwind safelist: md:grid-cols-1 md:grid-cols-2 md:grid-cols-3 md:grid-cols-4
      GRID_COLS = {
        1 => "md:grid-cols-1",
        2 => "md:grid-cols-2",
        3 => "md:grid-cols-3",
        4 => "md:grid-cols-4"
      }.freeze

      renders_many :columns, ->(title:, status:, color: :ghost, count: nil, **opts) do
        Column::Component.new(
          title: title, status: status, color: color, count: count,
          sortable_config: sortable_config, **opts
        )
      end

      # @param resource_name [String] Name of the resource for position params (e.g., "roadmap_item")
      # @param group_name [String] SortableJS group name for cross-column dragging (default: "kanban")
      # @param list_param_name [String] Param name sent for the target column (default: "status")
      # @param response_kind [Symbol] :html or :turbo_stream (default: :html)
      def initialize(
        resource_name: nil,
        group_name: "kanban",
        list_param_name: "status",
        response_kind: :html,
        **options
      )
        @resource_name = resource_name
        @group_name = group_name
        @list_param_name = list_param_name
        @response_kind = response_kind
        @options = options
      end

      private

      attr_reader :resource_name, :group_name, :list_param_name, :response_kind, :options

      def sortable_config
        { group_name:, list_param_name:, resource_name:, response_kind: }
      end

      # A drop is a mouse gesture with no textual result: the DOM changes, the
      # focus does not move, and nothing is announced. The live region is the
      # only way the outcome reaches a screen reader, so the board owns one and
      # listens for the drop the columns' SortableLists dispatch.
      #
      # The sentence is interpolated in JavaScript, so Ruby hands the controller
      # the translated template rather than a finished string.
      def board_attributes
        {
          class: "kanban-component",
          data: {
            controller: "kanban",
            action: "bali:sortable-list:end->kanban#announce",
            kanban_announcement_value: I18n.t("bali_view.kanban.card_moved")
          }
        }
      end

      def grid_classes
        col_class = GRID_COLS.fetch(columns.size.clamp(1, 4), GRID_COLS[4])
        class_names("grid grid-cols-1 gap-4", col_class, options[:class])
      end
    end
  end
end
