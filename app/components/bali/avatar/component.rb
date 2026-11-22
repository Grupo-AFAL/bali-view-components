# frozen_string_literal: true

module Bali
  module Avatar
    class Component < ApplicationViewComponent
      include Utils::ColorCalculator

      renders_one :picture, ->(image_url:, **options) {
        Picture::Component.new(image_url: image_url, **options)
      }
      renders_one :placeholder

      SIZES = {
        xs: "w-8",
        sm: "w-12",
        md: "w-16",
        lg: "w-24",
        xl: "w-32"
      }.freeze

      PLACEHOLDER_TEXT_SIZES = {
        xs: "text-xs",
        sm: "text-sm",
        md: "text-base",
        lg: "text-xl",
        xl: "text-3xl"
      }.freeze

      SHAPES = {
        square: "rounded",
        rounded: "rounded-xl",
        circle: "rounded-full"
      }.freeze

      MASKS = {
        heart: "mask mask-heart",
        squircle: "mask mask-squircle",
        hexagon: "mask mask-hexagon-2",
        triangle: "mask mask-triangle",
        diamond: "mask mask-diamond",
        pentagon: "mask mask-pentagon",
        star: "mask mask-star"
      }.freeze

      # Connectors inside a Spanish name ("Rodríguez de la Garza", "María del Carmen"):
      # `initials` does not count them as words.
      NAME_PARTICLES = %w[de del la las los y].freeze

      STATUSES = {
        online: "avatar-online",
        offline: "avatar-offline"
      }.freeze

      RING_COLORS = {
        primary: "ring-primary",
        secondary: "ring-secondary",
        accent: "ring-accent",
        neutral: "ring-base-content",
        success: "ring-success",
        warning: "ring-warning",
        error: "ring-error",
        info: "ring-info"
      }.freeze

      # rubocop:disable Metrics/ParameterLists
      def initialize(src: nil, name: nil, initials: nil, size: :md, shape: :circle,
                     mask: nil, status: nil, ring: nil, **options)
        # rubocop:enable Metrics/ParameterLists
        @src = src
        @name = name.presence
        @initials = initials.presence
        @size = size&.to_sym
        @shape = shape&.to_sym
        @mask = mask&.to_sym
        @status = status&.to_sym
        @ring = ring&.to_sym
        @options = options
      end

      def container_classes
        class_names(
          "avatar",
          STATUSES[@status],
          (placeholder? || initials?) && "avatar-placeholder",
          @options[:class]
        )
      end

      def container_attributes
        attrs = @options.except(:class)
        return attrs if @name.blank? || aria_hidden?(attrs)

        attrs[:title] = @name unless attrs.key?(:title)
        return attrs if image? || attrs.key?(:role)

        attrs[:role] = "img"
        attrs[:"aria-label"] = @name unless labelled?(attrs)
        attrs
      end

      def inner_attributes
        attrs = {
          class: class_names(
            inner_classes,
            (placeholder_classes if placeholder?),
            (placeholder_text_size if initials?)
          )
        }
        attrs[:style] = initials_style if initials?
        attrs
      end

      def inner_classes
        class_names(
          SIZES[@size],
          shape_classes,
          @mask.nil? && "aspect-square",
          ring_classes
        )
      end

      def placeholder_classes
        class_names(
          "bg-neutral",
          "text-neutral-content",
          placeholder_text_size
        )
      end

      # Spanish names run given names, then two surnames, so from three words up the
      # letters are the first word and the penultimate one — the first surname — where the
      # last word read "Federico Gonzalez Lutteroth" as "FL". The NAME_PARTICLES are not
      # words, or "Rodríguez de la Garza" would end on the surname "la". No position can
      # tell a surname from a second given name, so one surname after two given names
      # ("Juan Carlos Pérez", "María del Carmen López") reads "JC" and "MC": pass
      # `initials:`, which always wins over the derivation. Words that do not start with a
      # letter are skipped; none left means no initials.
      def initials
        @derived_initials ||= @initials || derive_initials
      end

      def image_alt
        @options[:alt] || @name || ""
      end

      private

      def shape_classes
        @mask ? MASKS[@mask] : SHAPES.fetch(@shape, SHAPES[:circle])
      end

      def ring_classes
        return unless @ring

        class_names(
          "ring-2 ring-offset-base-100 ring-offset-2",
          RING_COLORS[@ring]
        )
      end

      def image?
        picture? || @src.present?
      end

      def placeholder?
        placeholder.present? && !image?
      end

      def initials?
        initials.present? && !image? && placeholder.blank?
      end

      def derive_initials
        words = @name.to_s.split.grep(/\A\p{L}/)
                     .reject { |word| NAME_PARTICLES.include?(word.downcase) }
        words = [ words.first, words[-2] ] if words.size > 2
        # `\X`, not `[0]`: a decomposed "Á" is "A" plus U+0301.
        words.map { |word| word[/\X/] }.join.upcase.presence
      end

      # Inline style, like Status: the same person gets the same colour on
      # every theme and render, with no Tailwind safelist.
      def initials_style
        pair = deterministic_color(@name || @initials)
        "background-color: #{pair[:bg]}; color: #{pair[:fg]};"
      end

      def labelled?(attrs)
        attrs.key?(:"aria-label") || attrs.dig(:aria, :label).present?
      end

      def aria_hidden?(attrs)
        [ attrs[:"aria-hidden"], attrs.dig(:aria, :hidden) ].any? { |value| value.to_s == "true" }
      end

      def placeholder_text_size
        PLACEHOLDER_TEXT_SIZES.fetch(@size, "text-xl")
      end
    end
  end
end
