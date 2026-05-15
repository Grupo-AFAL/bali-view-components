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

      def grid_classes
        col_class = GRID_COLS.fetch(columns.size.clamp(1, 4), GRID_COLS[4])
        class_names("grid grid-cols-1 gap-4", col_class, options[:class])
      end
    end
  end
end
