# frozen_string_literal: true

module Bali
  module Kanban
    module Column
      class Component < ApplicationViewComponent
        renders_many :cards, Card::Component

        BADGE_COLORS = {
          primary: "badge-primary",
          secondary: "badge-secondary",
          accent: "badge-accent",
          info: "badge-info",
          success: "badge-success",
          warning: "badge-warning",
          error: "badge-error",
          ghost: "badge-ghost"
        }.freeze

        # @param title [String] Column header text
        # @param status [String] Status value sent as list_id on drop (e.g., "planned")
        # @param color [Symbol] DaisyUI badge color for the header indicator
        # @param count [Integer, nil] Item count badge (auto-counted from cards if nil)
        # @param sortable_config [Hash] SortableList options passed from parent Kanban
        def initialize(title:, status:, color: :ghost, count: nil, sortable_config: {}, **options)
          @title = title
          @status = status
          @color = color.to_sym
          @count = count
          @sortable_config = sortable_config
          @options = options
        end

        private

        attr_reader :title, :status, :color, :count, :sortable_config, :options

        def display_count
          count || cards.size
        end

        def badge_class
          BADGE_COLORS.fetch(color, BADGE_COLORS[:ghost])
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
