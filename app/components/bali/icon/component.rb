# frozen_string_literal: true

module Bali
  module Icon
    # Renders icons from multiple sources with a consistent API.
    #
    # Resolution order:
    # 1. Lucide icons (via lucide-rails gem) - primary source for UI icons
    # 2. Kept icons (brands, regional, custom) - from original Bali icon set
    # 3. Custom icons (via Bali.custom_icons) - app-specific extensions
    # 4. Legacy icons (DefaultIcons) - fallback for full backwards compatibility
    #
    # @example Basic usage
    #   render Bali::Icon::Component.new('user')
    #
    # @example With size
    #   render Bali::Icon::Component.new('check', size: :large)
    #
    # @example With custom classes
    #   render Bali::Icon::Component.new('alert', class: 'text-error')
    #
    class Component < ApplicationViewComponent
      attr_reader :name, :tag_name, :options

      SIZES = {
        small: 'size-4',
        medium: 'size-8',
        large: 'size-12'
      }.freeze

      # Size mappings for Lucide icons (in pixels)
      LUCIDE_SIZES = {
        small: 16,
        medium: 32,
        large: 48
      }.freeze

      # SVG size classes for child elements
      SIZE_SVG_CLASSES = {
        medium: '*:h-8 *:w-8',
        large: '*:h-12 *:w-12'
      }.freeze

      # @param name [String, Symbol] Icon name (Bali name or Lucide name)
      # @param tag_name [Symbol] HTML tag to wrap the icon (:span, :div, etc.)
      # @param size [Symbol] Icon size (:small, :medium, :large)
      # @param options [Hash] Additional HTML attributes
      def initialize(name, tag_name: :span, size: nil, **options)
        @name = name.to_s
        @tag_name = tag_name
        @size = size
        @options = prepend_class_name(options, component_classes)
      end

      def call
        tag.send(tag_name, **options) { resolve_icon.html_safe }
      end

      private

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

        # 5. Fall back to legacy DefaultIcons (full backwards compatibility)
        return render_legacy_icon(@name) if legacy_icon_exists?(@name)

        # No icon found - raise descriptive error
        raise Options::IconNotAvailable, icon_not_found_message
      end

      # Renders a Lucide icon using the lucide-rails provider
      #
      # @param lucide_name [String] the Lucide icon name
      # @return [String] SVG markup
      def render_lucide_icon(lucide_name)
        pixel_size = LUCIDE_SIZES[@size] || 16
        svg_content = LucideRails::IconProvider.icon(lucide_name)

        tag.svg(
          svg_content.html_safe,
          **LucideRails.default_options,
          width: pixel_size,
          height: pixel_size,
          class: 'lucide-icon'
        )
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

      # Checks if a legacy icon exists in DefaultIcons
      #
      # @param icon_name [String] the icon name to check
      # @return [Boolean]
      def legacy_icon_exists?(icon_name)
        DefaultIcons.const_defined?(normalize_constant_name(icon_name))
      rescue NameError
        false
      end

      # Renders a legacy icon from DefaultIcons
      #
      # @param icon_name [String] the icon name
      # @return [String] SVG markup
      def render_legacy_icon(icon_name)
        DefaultIcons.const_get(normalize_constant_name(icon_name))
      end

      # Converts icon name to Ruby constant format
      #
      # @param name [String] icon name like 'arrow-left'
      # @return [String] constant name like 'ARROW_LEFT'
      def normalize_constant_name(name)
        name.to_s.upcase.tr('-', '_')
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
                 ' Check available icons at: https://lucide.dev/icons'
               end

        msg
      end

      # Finds similar icon names for better error messages
      #
      # @param name [String] the icon name that wasn't found
      # @return [Array<String>] up to 3 similar icon names
      def find_similar_icons(name)
        all_names = LucideMapping.bali_names + KeptIcons::ALL
        all_names.select { |n| n.include?(name) || name.include?(n) }.first(3)
      end

      def component_classes
        class_names(
          'icon-component',
          'inline-flex items-center justify-center',
          '*:inline-block *:h-4 *:w-4 *:overflow-visible',
          SIZES[@size],
          SIZE_SVG_CLASSES[@size]
        )
      end
    end
  end
end
