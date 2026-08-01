# frozen_string_literal: true

module Bali
  module Utils
    # Walks a palette, handing out one colour per series. The palette itself is
    # Bali::Color's — this class used to keep three of its own (THEME_COLORS,
    # CSS_VAR_MAP, FALLBACK_COLORS), of which two were read by nothing.
    class ColorPicker
      class << self
        def opacify(color, opacity = 5)
          return Bali::Color.with_alpha(color, opacity * 10) unless color.to_s.start_with?("#")

          "#{color}#{(opacity * 255 / 10).to_fs(16)}"
        end
      end

      attr_reader :current, :use_theme_colors

      # @param use_theme_colors [Boolean] Resolve to DaisyUI variables rather than fixed hex
      # @param color [Symbol, nil] Semantic colour the cycle starts from
      # @param custom_color [String, nil] Hex colour the cycle starts from
      def initialize(use_theme_colors: true, color: nil, custom_color: nil)
        @pointer = 0
        @use_theme_colors = use_theme_colors
        @color = color
        @custom_color = custom_color
        @current = colors[@pointer]
      end

      def next_color
        color = colors[@pointer]
        @pointer += 1
        reset_pointer if pointer_out_of_range?

        @current = color
      end

      def opacify_current(opacity = 5)
        self.class.opacify(@current, opacity)
      end

      private

      def pointer_out_of_range?
        @pointer >= (colors.size - 1)
      end

      def reset_pointer
        @pointer = 0
      end

      # A hex `custom_color:` takes the whole palette off the theme, not just its
      # first entry. Mixing the two would hand Chart.js one hex and six
      # `var(--color-*)` strings in the same dataset, and canvas cannot resolve a
      # var() — the theme half would render as nothing.
      def colors
        @colors ||= if @custom_color
                      [ @custom_color, *legacy_colors ]
        elsif @use_theme_colors
                      theme_aware_colors
        else
                      legacy_colors
        end
      end

      # Rotated so a declared `color:` leads it, which is what makes a
      # single-series chart honour one.
      def theme_aware_colors
        Bali::Color.cycle_from(@color).map { |name| Bali::Color.css(name) }
      end

      # Fixed hex, for a host that opts out of the theme with `use_theme_colors: false`
      def legacy_colors
        [
          "#22AA99", # turquoise
          "#3366CC", # blue
          "#DC3912", # red
          "#FF9900", # yellow
          "#109618", # green
          "#990099", # purple
          "#DD4477", # pink
          "#66AA00", # light_green
          "#E67300", # dark_yellow
          "#AAAA11" # olive
        ]
      end
    end
  end
end
