# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      include Utils::ColorCalculator

      BASE_CLASSES = "badge tag-component"

      COLORS = {
        neutral: "badge-neutral",
        primary: "badge-primary",
        secondary: "badge-secondary",
        accent: "badge-accent",
        ghost: "badge-ghost",
        info: "badge-info",
        success: "badge-success",
        warning: "badge-warning",
        error: "badge-error"
      }.freeze

      SIZES = {
        xs: "badge-xs",
        sm: "badge-sm",
        md: "badge-md",
        lg: "badge-lg",
        xl: "badge-xl"
      }.freeze

      STYLES = {
        outline: "badge-outline",
        soft: "badge-soft",
        dash: "badge-dash"
      }.freeze

      # The Bulma names v1 and v2 also accepted, mapped to what replaces them.
      # Kept as data so a call site that never migrated is told which value to
      # write instead of being handed the whole list of valid ones.
      LEGACY_COLORS = {
        danger: :error,
        link: :primary,
        black: :neutral,
        dark: :neutral,
        light: :ghost,
        white: :ghost
      }.freeze

      LEGACY_SIZES = {
        small: :sm,
        medium: :md,
        large: :lg,
        normal: :md
      }.freeze

      LIGHT_REMOVED_MESSAGE = "Bali::Tag::Component no longer accepts `light:`. " \
                              "Use `style: :outline`."

      # rubocop:disable Metrics/ParameterLists
      def initialize(text: nil, href: nil, color: nil, custom_color: nil, size: nil,
                     style: nil, rounded: false, **options)
        # rubocop:enable Metrics/ParameterLists
        reject_light!(options)

        @text = text
        @href = href
        @color_class = variant_class(:color, color, COLORS, LEGACY_COLORS)
        @size_class = variant_class(:size, size, SIZES, LEGACY_SIZES)
        @custom_color = custom_color
        @style = style&.to_sym
        @rounded = rounded
        @options = options
      end

      private

      attr_reader :text, :href

      def tag_name
        href.present? ? :a : :div
      end

      def component_classes
        class_names(
          BASE_CLASSES,
          @color_class,
          @size_class,
          STYLES[@style],
          @rounded && "rounded-full",
          @options[:class]
        )
      end

      # nil is how every optional variant is spelled, so it stays a no-op.
      # Anything else has to be a key: dropping the variant when the value is
      # not one is how the Bulma names survived two majors past their removal
      # note — `color: :danger` rendered an uncoloured tag and nothing said so.
      def variant_class(param, value, classes, legacy)
        return nil if value.nil?

        key = value.to_sym
        classes.fetch(key) { raise ArgumentError, rejection_message(param, key, classes, legacy) }
      end

      def rejection_message(param, key, classes, legacy)
        replacement = legacy[key]

        if replacement
          "Bali::Tag::Component: #{param} #{key.inspect} is a Bulma name removed in v3. " \
            "Use #{param}: #{replacement.inspect}."
        else
          "Bali::Tag::Component: unknown #{param} #{key.inspect}. " \
            "Valid: #{classes.keys.map(&:inspect).join(', ')}."
        end
      end

      # `light:` is gone from the signature, so without this it would land in
      # **options and render as a `light="true"` HTML attribute — the same
      # silent nothing the Bulma colours produced.
      def reject_light!(options)
        raise ArgumentError, LIGHT_REMOVED_MESSAGE if options.key?(:light)
      end

      def custom_styles
        styles = []

        if @custom_color.present?
          styles << "background-color: #{@custom_color}"
          styles << "color: #{contrasting_text_color(@custom_color)}"
        end

        styles << @options[:style] if @options[:style].present?
        styles.join("; ").presence
      end

      def html_attributes
        attrs = @options.except(:class, :style)
        attrs[:href] = href if href.present?
        attrs[:style] = custom_styles if custom_styles.present?
        attrs
      end
    end
  end
end
