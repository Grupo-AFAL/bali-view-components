# frozen_string_literal: true

module Bali
  module Icon
    # Renders icons from multiple sources with a consistent API.
    #
    # Resolution order:
    # 1. Lucide icons (via lucide-rails gem) - primary source for UI icons
    # 2. Kept icons (brands, regional, custom) - from original Bali icon set
    # 3. Custom icons (via Bali.custom_icons) - app-specific extensions
    #
    # Names are matched exactly: a name that is neither mapped, nor a Lucide
    # name, nor kept, nor registered raises instead of falling back.
    #
    # @example Basic usage
    #   render Bali::Icon::Component.new('user')
    #
    # @example With size
    #   render Bali::Icon::Component.new('check', size: :large)
    #
    # @example With numeric size (pixels)
    #   render Bali::Icon::Component.new('check', size: 24)
    #
    # @example With custom classes
    #   render Bali::Icon::Component.new('alert', class: 'text-error')
    #
    class Component < ApplicationViewComponent
      attr_reader :name, :tag_name, :options

      SIZES = {
        small: "size-4",
        medium: "size-8",
        large: "size-12"
      }.freeze

      # Size mappings for Lucide icons (in pixels)
      LUCIDE_SIZES = {
        small: 16,
        medium: 32,
        large: 48
      }.freeze

      # SVG size classes for child elements
      SIZE_SVG_CLASSES = {
        medium: "*:h-8 *:w-8",
        large: "*:h-12 *:w-12"
      }.freeze

      # @param name [String, Symbol] Icon name (Bali name or Lucide name)
      # @param tag_name [Symbol] HTML tag to wrap the icon (:span, :div, etc.)
      # @param size [Symbol, Numeric] Icon size — :small / :medium / :large or
      #   an integer in pixels (e.g. 24)
      # @param options [Hash] Additional HTML attributes
      def initialize(name, tag_name: :span, size: nil, **options)
        @name = name.to_s
        @tag_name = tag_name
        @size = size
        options = apply_size_style(options) if numeric_size?
        @options = hide_from_assistive_tech(prepend_class_name(options, component_classes))
      end

      def call
        tag.send(tag_name, **options) { resolve_icon.html_safe }
      end

      private

      # An icon is decorative unless its host says otherwise: the meaning is in
      # the text or in the accessible name of the control it sits in, and an
      # unlabelled SVG announces nothing useful anyway. Lucide already emits
      # `aria-hidden` on its own `<svg>`; the kept, custom and legacy sources do
      # not, so it goes on the wrapper where it covers all four (#685).
      #
      # Pass `"aria-hidden": false` to expose an icon that really is the only
      # carrier of meaning — but give it a name too, or it stays anonymous.
      def hide_from_assistive_tech(options)
        return options if options.key?(:"aria-hidden") || options.key?("aria-hidden")

        options.merge("aria-hidden": true)
      end

      # Resolves the icon through the resolution pipeline
      #
      # @return [String] SVG markup for the icon
      # @raise [Options::IconNotAvailable] if icon cannot be resolved
      def resolve_icon
        # 1. Try Lucide mapping (Bali name → Lucide name)
        if (lucide_name = LucideMapping.find(@name))
          return render_lucide_icon(lucide_name)
        end

        # 2. Try direct Lucide name (allows using Lucide names directly)
        return render_lucide_icon(@name) if lucide_icon_exists?(name)

        # 3. Try kept icons (brands, regional, custom domain-specific)
        return KeptIcons.find(@name) if KeptIcons.exists?(@name)

        # 4. Try custom icons (app-specific via Bali.custom_icons)
        return Bali.custom_icons[@name].html_safe if Bali.custom_icons.key?(@name)

        # No icon found - raise descriptive error
        raise Options::IconNotAvailable, icon_not_found_message
      end

      # Renders a Lucide icon using the lucide-rails provider
      #
      # @param lucide_name [String] the Lucide icon name
      # @return [String] SVG markup
      def render_lucide_icon(lucide_name)
        svg_content = LucideRails::IconProvider.icon(lucide_name)

        tag.svg(
          svg_content.html_safe,
          **LucideRails.default_options,
          width: pixel_size,
          height: pixel_size,
          class: "lucide-icon"
        )
      end

      def numeric_size?
        @size.is_a?(Numeric)
      end

      def pixel_size
        return @size.to_i if numeric_size?

        LUCIDE_SIZES[@size] || 16
      end

      def apply_size_style(options)
        px = "#{@size.to_i}px"
        sizing = "width: #{px}; height: #{px}; --bali-icon-size: #{px}"
        options.merge(style: [ sizing, options[:style] ].compact.join("; "))
      end

      # Checks if a Lucide icon exists
      #
      # @param icon_name [String] the icon name to check
      # @return [Boolean]
      def lucide_icon_exists?(icon_name)
        LucideRails::IconProvider.icon(icon_name.to_s)
        true
      rescue ArgumentError
        false
      end

      # Generates a helpful error message for missing icons
      #
      # @return [String]
      def icon_not_found_message
        suggestions = find_similar_icons(@name)
        msg = "Icon '#{@name}' is not available."

        msg += if suggestions.any?
                 " Did you mean: #{suggestions.join(', ')}?"
        else
                 " Check available icons at: https://lucide.dev/icons"
        end

        msg
      end

      # Finds similar icon names for better error messages
      #
      # Matching ignores the difference between dashes and underscores, because
      # the removed legacy step accepted both spellings of every name it
      # served — without that, `arrow_left` suggests nothing at all instead of
      # the `arrow-left` that replaces it.
      #
      # @param name [String] the icon name that wasn't found
      # @return [Array<String>] up to 3 similar icon names
      def find_similar_icons(name)
        needle = comparable_name(name)
        all_names = LucideMapping.bali_names + KeptIcons::ALL

        all_names.select do |candidate|
          comparable = comparable_name(candidate)
          comparable.include?(needle) || needle.include?(comparable)
        end.first(3)
      end

      def comparable_name(name)
        name.to_s.downcase.tr("_", "-")
      end

      def component_classes
        return numeric_component_classes if numeric_size?

        class_names(
          "icon-component",
          "inline-flex items-center justify-center",
          "*:inline-block *:h-4 *:w-4 *:overflow-visible",
          SIZES[@size],
          SIZE_SVG_CLASSES[@size]
        )
      end

      # Numeric sizes drive the wrapper and direct children via inline style
      # plus the `--bali-icon-size` CSS variable, so no Tailwind safelist is
      # required and consumers can pass any pixel value.
      def numeric_component_classes
        class_names(
          "icon-component",
          "inline-flex items-center justify-center",
          "*:inline-block *:overflow-visible"
        )
      end
    end
  end
end
