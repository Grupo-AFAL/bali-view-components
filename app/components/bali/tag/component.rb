# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      include Utils::ColorCalculator

      BASE_CLASSES = "badge tag-component"

      # Keyed by Bali::Color::NAMES; the values are spelled out because Tailwind
      # only emits a class it can find as a literal string in a source file.
      COLORS = {
        neutral: "badge-neutral",
        primary: "badge-primary",
        secondary: "badge-secondary",
        accent: "badge-accent",
        info: "badge-info",
        success: "badge-success",
        warning: "badge-warning",
        error: "badge-error",
        ghost: "badge-ghost"
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

      # Pixel sizes for the `icon:` keyword, one per badge size and matched to
      # the font-size daisyUI gives that size. The Icon default (16px) equals
      # the full height of a `badge-xs` pill, so an unsized glyph would touch
      # both edges; drawn at the text's own size it sits inside the padding box
      # at every size. The slot is the escape hatch for any other size.
      ICON_SIZES = { xs: 10, sm: 12, md: 14, lg: 16, xl: 18 }.freeze

      # The Bulma colour names are shared with every other component that takes a
      # `color:`, so they live in Bali::Color. The sizes are Tag's alone.
      LEGACY_COLORS = Bali::Color::LEGACY

      LEGACY_SIZES = {
        small: :sm,
        medium: :md,
        large: :lg,
        normal: :md
      }.freeze

      LIGHT_REMOVED_MESSAGE = "Bali::Tag::Component no longer accepts `light:`. " \
                              "Use `style: :outline`."

      # The slot and the `icon:` keyword are the same concept written two ways,
      # mirroring Bali::Link: the keyword is the common case and draws the glyph
      # at the pill's own text size; the slot is the one that takes options
      # (`with_icon('star', class: 'text-error')`), so it wins when both are
      # given.
      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }

      # @param icon [String, Symbol] Icon name, drawn before the text.
      # rubocop:disable Metrics/ParameterLists
      def initialize(text: nil, href: nil, color: nil, custom_color: nil, size: nil,
                     style: nil, rounded: false, icon: nil, **options)
        # rubocop:enable Metrics/ParameterLists
        reject_light!(options)

        @text = text
        @href = href
        @icon = icon
        @size = size&.to_sym
        @color_class = COLORS[Bali::Color.name!(self.class, color)]
        @size_class = variant_class(:size, size, SIZES, LEGACY_SIZES)
        @custom_color = Bali::Color.hex!(self.class, custom_color)
        @style = style&.to_sym
        @rounded = rounded
        @options = options
      end

      private

      attr_reader :text, :href

      def tag_name
        href.present? ? :a : :div
      end

      # A `size:` that is not a key raised in the constructor, so by now @size
      # is either valid or nil — and nil renders daisyUI's default, which is md.
      def keyword_icon_size
        ICON_SIZES.fetch(@size || :md)
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

      # The size half of what Bali::Color does for colours: nil is how an
      # optional variant is spelled and stays a no-op, anything else has to be a
      # key. Dropping the variant when the value is not one is how the Bulma
      # names survived two majors past their removal note — `size: :small`
      # rendered a default-sized tag and nothing said so.
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
