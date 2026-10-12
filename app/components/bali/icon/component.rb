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
    #   render Bali::Icon::Component.new('alert', class: 'text-soft-error')
    #
    class Component < ApplicationViewComponent
      attr_reader :name, :tag_name, :options

      # Every name the direct-Lucide step can serve, enumerated from the SVG
      # files the gem ships (lucide-rails has no list API). Only the error
      # path reads it — it feeds "did you mean" for names the mapping no
      # longer carries, e.g. `arrow_left` → `arrow-left` (#902 removed the
      # identity entries that used to cover those). Memoized: the set is
      # fixed for the life of the process.
      def self.lucide_icon_names
        @lucide_icon_names ||= LucideRails::GEM_ROOT
                               .glob("icons/stripped/*.svg")
                               .map { |file| file.basename(".svg").to_s }
                               .sort.freeze
      end

      # In pixels.
      SIZES = {
        small: 16,
        medium: 32,
        large: 48
      }.freeze

      # Nothing but the hook: bali/general.css holds the look, where a caller's utility wins.
      CLASSES = "icon-component"

      # @param name [String, Symbol] Icon name (Bali name or Lucide name)
      # @param tag_name [Symbol] HTML tag to wrap the icon (:span, :div, etc.)
      # @param size [Symbol, Numeric] Icon size — :small / :medium / :large or
      #   an integer in pixels (e.g. 24). A size utility in `class:` (`size-6`,
      #   `w-5 h-5`) wins over it.
      # @param options [Hash] Additional HTML attributes
      def initialize(name, tag_name: :span, size: nil, **options)
        @name = name.to_s
        @tag_name = tag_name
        @size = known_size(size)
        options = apply_size_style(options) if size
        @options = hide_from_assistive_tech(prepend_class_name(options, CLASSES))
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

        # `default_options` carries "width"/"height" as String keys (24); the
        # Symbol overrides below would serialize as a SECOND pair, and HTML
        # parsers keep the first — so 24 always won and `size:` never reached
        # the SVG (#986).
        tag.svg(
          svg_content.html_safe,
          **LucideRails.default_options.except("width", "height"),
          width: pixel_size,
          height: pixel_size,
          class: "lucide-icon"
        )
      end

      def numeric_size?
        @size.is_a?(Numeric)
      end

      # An unknown key used to fall back to 16px without a word, which is how
      # `size: :sm` lived on in Avatar::Upload.
      def known_size(size)
        return size if size.nil? || size.is_a?(Numeric)
        return size.to_sym if SIZES.key?(size.to_sym)

        raise ArgumentError, "Bali::Icon::Component: unknown size #{size.to_sym.inspect}. " \
                             "Valid: #{SIZES.keys.map(&:inspect).join(', ')}, or pixels as a number."
      end

      def pixel_size
        return @size.to_i if numeric_size?

        SIZES.fetch(@size, 16)
      end

      # Only the variable: an inline `width`/`height` would outrank a caller's `size-*`.
      def apply_size_style(options)
        options.merge(style: [ "--bali-icon-size: #{size_value}", options[:style] ].compact.join("; "))
      end

      # Named sizes in rem, like the 1rem default in bali/general.css, so a root font-size
      # other than 16px moves them together.
      def size_value
        numeric_size? ? "#{@size.to_i}px" : "#{pixel_size / 16}rem"
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
      # the `arrow-left` that replaces it. Candidates cover everything the
      # pipeline can actually serve: the mapping's keys, the full Lucide set,
      # and the kept icons.
      #
      # @param name [String] the icon name that wasn't found
      # @return [Array<String>] up to 3 similar icon names
      def find_similar_icons(name)
        needle = comparable_name(name)
        all_names = LucideMapping.bali_names + self.class.lucide_icon_names + KeptIcons::ALL

        all_names.select do |candidate|
          comparable = comparable_name(candidate)
          comparable.include?(needle) || needle.include?(comparable)
        end.uniq.sort_by { |candidate| [ suggestion_rank(candidate, needle), candidate ] }.first(3)
      end

      # Exact match (modulo dash/underscore) first, then prefix, then the rest.
      # Without the ranking, `first(3)` truncates in pool order and `panel_left`
      # loses `panel-left` itself to `layout-panel-left` (#985).
      def suggestion_rank(candidate, needle)
        comparable = comparable_name(candidate)
        return 0 if comparable == needle
        return 1 if comparable.start_with?(needle)

        2
      end

      def comparable_name(name)
        name.to_s.downcase.tr("_", "-")
      end
    end
  end
end
