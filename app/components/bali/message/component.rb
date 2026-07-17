# frozen_string_literal: true

module Bali
  module Message
    class Component < ApplicationViewComponent
      BASE_CLASSES = "alert message-component"

      COLORS = {
        primary: "alert-info",
        secondary: "alert",
        success: "alert-success",
        danger: "alert-error",
        warning: "alert-warning",
        info: "alert-info",
        link: "alert-info"
      }.freeze

      SIZES = {
        small: "text-sm",
        regular: "",
        medium: "text-base",
        large: "text-lg"
      }.freeze

      STYLES = {
        soft: "alert-soft",
        outline: "alert-outline",
        dash: "alert-dash"
      }.freeze

      # Allowed ARIA live-region roles. `alert` is assertive (interrupts the
      # screen reader), `status` is polite, `note` is a non-live annotation.
      ROLES = %i[alert status note].freeze

      renders_one :header

      # Role precedence (highest to lowest):
      #   1. `role:` — the primary contract; validated against ROLES, unknown
      #      values fall back to :alert.
      #   2. `assertive: true` — sugar for role :alert (only when `role:` omitted).
      #   3. `polite: true` — sugar for role :status (only when `role:` omitted).
      #   4. default — :alert.
      # `assertive:` wins over `polite:` when both are given.
      # rubocop:disable Metrics/ParameterLists
      def initialize(title: nil, size: :regular, color: :primary, style: nil,
                     role: nil, polite: false, assertive: false,
                     dismissible: false, dismiss_id: nil, **options)
        @title = title
        @size = size&.to_sym
        @color = color&.to_sym
        @style = style&.to_sym
        @role = resolve_role(role, polite: polite, assertive: assertive)
        @dismissible = dismissible
        @dismiss_id = dismiss_id
        @options = prepend_class_name(options, message_classes)
        @options = build_dismiss_options(@options) if dismissible
      end
      # rubocop:enable Metrics/ParameterLists

      private

      attr_reader :title, :role, :options

      def dismissible? = @dismissible

      def resolve_role(role, polite:, assertive:)
        return ROLES.include?(role.to_sym) ? role.to_sym : :alert if role
        return :alert if assertive
        return :status if polite

        :alert
      end

      def build_dismiss_options(options)
        options = prepend_controller(options, "message")
        prepend_values(options, "message", dismiss_id: @dismiss_id)
      end

      # Ghost/circle icon button pinned to the trailing edge of the alert.
      # `ml-auto` right-aligns it inside daisyUI's alert grid/flex layout.
      def close_button
        Bali::Button::Component.new(
          icon_name: "x",
          variant: :ghost,
          size: :sm,
          responsive: false,
          class: "btn-circle ml-auto message-dismiss",
          data: { action: "message#dismiss" },
          "aria-label": "Close"
        )
      end

      def message_classes
        class_names(
          BASE_CLASSES,
          COLORS.fetch(@color, COLORS[:primary]),
          SIZES.fetch(@size, SIZES[:regular]),
          STYLES[@style]
        )
      end
    end
  end
end
