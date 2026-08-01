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
        # @param sortable_config [Hash] SortableList options passed from parent Kanban
        # rubocop:disable Metrics/ParameterLists
        def initialize(title:, status:, color: :ghost, custom_color: nil, count: nil,
                       sortable_config: {}, **options)
          # rubocop:enable Metrics/ParameterLists
          @title = title
          @status = status
          # Validated here as well as in the Tag it feeds, so the message names
          # the class the caller actually wrote.
          @custom_color = Bali::Color.hex!(self.class, custom_color)
          @color = @custom_color ? nil : Bali::Color.name!(self.class, color)
          @count = count
          @sortable_config = sortable_config
          @options = options
        end

        private

        attr_reader :title, :status, :color, :custom_color, :count, :sortable_config, :options

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
            animation: 150
          }
        end
      end
    end
  end
end
