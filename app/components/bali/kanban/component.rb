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

      LAYOUTS = %i[grid flow].freeze

      # 17rem is the header chrome the reference boards (afal-apps) leave above
      # the fold. It is a guess about the host's layout, which is why the offset
      # is a CSS variable — override `--bali-kanban-offset` on any ancestor —
      # and why `height:` is opt-in rather than a default.
      VIEWPORT_HEIGHT_CLASS = "h-[calc(100vh-var(--bali-kanban-offset,17rem))]"

      renders_many :columns, ->(title:, status:, color: :ghost, count: nil, **opts) do
        Column::Component.new(
          title: title, status: status, color: color, count: count,
          sortable_config: sortable_config, layout: layout, **opts
        )
      end

      # @param resource_name [String] Name of the resource for position params (e.g., "roadmap_item")
      # @param group_name [String] SortableJS group name for cross-column dragging (default: "kanban")
      # @param list_param_name [String] Param name sent for the target column (default: "status")
      # @param response_kind [Symbol] :html or :turbo_stream (default: :html)
      # @param layout [Symbol] :grid (default) caps at 4 columns side by side;
      #   :flow lays every column on one horizontally scrolling row (w-72 each)
      # @param height [Symbol, String, nil] nil (default: the board grows with its
      #   content), :viewport (cap to the visible viewport minus
      #   `--bali-kanban-offset`, 17rem by default), or a height utility class.
      #   A bounded board scrolls each column's card list internally.
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        resource_name: nil,
        group_name: "kanban",
        list_param_name: "status",
        response_kind: :html,
        layout: :grid,
        height: nil,
        **options
      )
        # rubocop:enable Metrics/ParameterLists
        @resource_name = resource_name
        @group_name = group_name
        @list_param_name = list_param_name
        @response_kind = response_kind
        @layout = validate_layout(layout)
        @height_class = height_class_for(height)
        @options = options
      end

      private

      attr_reader :resource_name, :group_name, :list_param_name, :response_kind, :layout,
                  :height_class, :options

      def validate_layout(layout)
        return layout if LAYOUTS.include?(layout)

        raise ArgumentError,
              "Unknown Bali::Kanban layout: #{layout.inspect}. Use one of #{LAYOUTS.inspect}"
      end

      def height_class_for(height)
        case height
        when nil then nil
        when :viewport then VIEWPORT_HEIGHT_CLASS
        when String then height
        else
          raise ArgumentError,
                "Unknown Bali::Kanban height: #{height.inspect}. " \
                "Use :viewport, a height utility class, or nil"
        end
      end

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

      def container_classes
        class_names(layout_classes, height_class, options[:class])
      end

      def layout_classes
        if layout == :flow
          "flex gap-4 overflow-x-auto"
        else
          col_class = GRID_COLS.fetch(columns.size.clamp(1, 4), GRID_COLS[4])
          "grid grid-cols-1 gap-4 #{col_class}"
        end
      end
    end
  end
end
