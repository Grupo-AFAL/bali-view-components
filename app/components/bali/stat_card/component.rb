# frozen_string_literal: true

module Bali
  module StatCard
    class Component < ApplicationViewComponent
      # Keyed by Bali::Color::NAMES. Spelled out because Tailwind only emits a
      # class it can find literally in a source file.
      COLORS = {
        neutral: { bg: "bg-neutral/10", text: "text-neutral" },
        primary: { bg: "bg-primary/10", text: "text-primary" },
        secondary: { bg: "bg-secondary/10", text: "text-secondary" },
        accent: { bg: "bg-accent/10", text: "text-accent" },
        info: { bg: "bg-info/10", text: "text-info" },
        success: { bg: "bg-success/10", text: "text-success" },
        warning: { bg: "bg-warning/10", text: "text-warning" },
        error: { bg: "bg-error/10", text: "text-error" },
        ghost: { bg: "bg-base-200", text: "text-base-content" }
      }.freeze

      DEFAULT_COLOR = :primary

      ICON_NAME_DEPRECATION = "Bali::StatCard::Component `icon_name:` is deprecated. " \
                              "Use `icon:`."

      renders_one :footer

      # @param title [String] Label above the value
      # @param value [String, Numeric] The figure the card exists to show
      # @param icon [String] Lucide icon name
      # @param color [Symbol] Semantic colour of the icon badge (Bali::Color::NAMES)
      # @param custom_color [String, nil] Hex colour for the icon badge
      # @param icon_name [String, nil] @deprecated Removed in Bali 4.0. Use `icon:`.
      # rubocop:disable Metrics/ParameterLists
      def initialize(title:, value:, icon: nil, color: DEFAULT_COLOR, custom_color: nil,
                     icon_name: nil, **options)
        # rubocop:enable Metrics/ParameterLists
        @title = title
        @value = value
        @icon = icon || deprecated_icon_name(icon_name)
        @custom_color = Bali::Color.hex!(self.class, custom_color)
        @color = @custom_color ? nil : Bali::Color.name!(self.class, color || DEFAULT_COLOR)
        @options = options
      end

      def card_options
        @options.merge(style: :bordered)
      end

      def icon_container_classes
        class_names("p-3 rounded-full", icon_bg_class)
      end

      def icon_container_style
        return if @custom_color.blank?

        "background-color: #{Bali::Color.with_alpha(@custom_color, 10)}"
      end

      def icon_bg_class
        COLORS.dig(@color, :bg)
      end

      def icon_text_class
        COLORS.dig(@color, :text)
      end

      def icon_style
        "color: #{@custom_color}" if @custom_color.present?
      end

      private

      attr_reader :title, :value, :icon, :color, :options

      # `icon_name:` has to stay in the signature rather than being deleted:
      # **options becomes HTML attributes, so a missed call site would render
      # `icon_name="users"` on the card and no icon, with nothing to read.
      def deprecated_icon_name(icon_name)
        return if icon_name.blank?

        Bali.deprecator.warn(ICON_NAME_DEPRECATION)
        icon_name
      end
    end
  end
end
