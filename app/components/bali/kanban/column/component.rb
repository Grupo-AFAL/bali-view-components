# frozen_string_literal: true

module Bali
  module Kanban
    module Column
      class Component < ApplicationViewComponent
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
        # @param count [Integer, nil] Item count badge (auto-counted from content if nil)
        # @param kanban [Bali::Kanban::Component] Parent kanban (set automatically)
        def initialize(title:, status:, color: :ghost, count: nil, kanban: nil, **options)
          @title = title
          @status = status
          @color = color.to_sym
          @count = count
          @kanban = kanban
          @options = options
        end

        private

        attr_reader :title, :status, :color, :count, :kanban, :options

        def badge_class
          BADGE_COLORS.fetch(color, BADGE_COLORS[:ghost])
        end

        def sortable_options
          {
            group_name: kanban&.send(:group_name) || "kanban",
            list_id: status,
            list_param_name: kanban&.send(:list_param_name) || "status",
            resource_name: kanban&.send(:resource_name),
            response_kind: kanban&.send(:response_kind) || :html,
            animation: 150
          }
        end
      end
    end
  end
end
