# frozen_string_literal: true

module Bali
  module Kanban
    module Column
      class Component < ApplicationViewComponent
        renders_many :cards, Card::Component

        # Rendered after the SortableList so its content is never draggable —
        # the "+ add card" pattern at the foot of a column.
        renders_one :footer

        # @param title [String] Column header text
        # @param status [String] Status value sent as list_id on drop (e.g., "planned")
        # @param color [Symbol] Semantic colour of the header indicator (Bali::Color::NAMES)
        # @param custom_color [String, nil] Hex colour for the header indicator
        # @param count [Integer, nil] Item count badge (auto-counted from cards if nil)
        # @param disabled [Boolean] Disable dragging cards out of this column
        # @param sortable_config [Hash] SortableList options passed from parent Kanban
        # @param layout [Symbol] Board layout, passed from parent Kanban (:grid or :flow)
        # rubocop:disable Metrics/ParameterLists
        def initialize(title:, status:, color: :ghost, custom_color: nil, count: nil,
                       disabled: false, sortable_config: {}, layout: :grid, **options)
          # rubocop:enable Metrics/ParameterLists
          @title = title
          @status = status
          # Validated here as well as in the Tag it feeds, so the message names
          # the class the caller actually wrote.
          @custom_color = Bali::Color.hex!(self.class, custom_color)
          @color = @custom_color ? nil : Bali::Color.name!(self.class, color)
          @count = count
          @disabled = disabled
          @sortable_config = sortable_config
          @layout = layout
          @options = options
        end

        private

        attr_reader :title, :status, :color, :custom_color, :count, :disabled,
                    :sortable_config, :layout, :options

        def display_count
          count || cards.size
        end

        def list_label
          I18n.t("bali_view.kanban.column_label", title: title, count: display_count)
        end
        # The indicator is a Tag, so the colour is a Tag's business: it owns the
        # `badge-*` table and the rejection of a name outside Bali::Color::NAMES.
        # The duplicate table this column used to keep answered `:ghost` to
        # anything it did not recognise, which quietly disagreed.
        def indicator_options
          { text: " ", color: color, custom_color: custom_color, size: :sm }
        end

        def sortable_options
          {
            group_name: sortable_config[:group_name] || "kanban",
            list_id: status,
            list_param_name: sortable_config[:list_param_name] || "status",
            resource_name: sortable_config[:resource_name],
            response_kind: sortable_config[:response_kind] || :html,
            disabled: disabled,
            animation: 150
          }
        end

        # `min-h-0` lets the column shrink below its content when the board caps
        # its height — without it the flex item refuses to shrink and the list
        # inside never overflows, so nothing ever scrolls.
        def column_classes
          class_names(
            "kanban-column bg-base-100 rounded-xl shadow-sm border border-base-200 p-4",
            "flex flex-col min-h-0",
            { "w-72 shrink-0" => layout == :flow },
            options[:class]
          )
        end
      end
    end
  end
end
