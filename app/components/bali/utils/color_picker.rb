# frozen_string_literal: true

module Bali
  module Utils
    class ColorPicker
      # DaisyUI theme-aware colors using CSS custom properties
      # These adapt automatically to light/dark mode
      THEME_COLORS = %w[
        primary
        secondary
        accent
        info
        success
        warning
        error
      ].freeze

      # Mapping from semantic color names to DaisyUI 5 CSS variable names
      # DaisyUI 5 uses full variable names like --color-primary instead of --p
      CSS_VAR_MAP = {
        'primary' => '--color-primary',
        'secondary' => '--color-secondary',
        'accent' => '--color-accent',
        'info' => '--color-info',
        'success' => '--color-success',
        'warning' => '--color-warning',
        'error' => '--color-error',
        'base-content' => '--color-base-content',
        'base-100' => '--color-base-100',
        'base-200' => '--color-base-200',
        'base-300' => '--color-base-300'
      }.freeze

      # Fallback hex colors (used when CSS variables are not available)
      # These match common DaisyUI theme defaults
      FALLBACK_COLORS = {
        'primary' => '#570df8',
        'secondary' => '#f000b8',
        'accent' => '#37cdbe',
        'info' => '#3abff8',
        'success' => '#36d399',
        'warning' => '#fbbd23',
        'error' => '#f87272'
      }.freeze

      class << self
        def opacify(color, opacity = 5)
          # Handle CSS variable references
          return css_color_with_alpha(color, opacity) if color.start_with?('var(')

          "#{color}#{(opacity * 255 / 10).to_fs(16)}"
        end

        def gradient(color = nil, size: 10)
          (0..(size - 1)).map { |opacity| opacify(color || @current, opacity) }
        end

        # Returns CSS color with alpha for theme colors
        def css_color_with_alpha(css_var, opacity)
          # Extract the variable name from var(--...)
          # For oklch colors, we need to use oklch(var(...) / alpha)
          alpha = opacity / 10.0
          var_match = css_var.match(/var\((--[^)]+)\)/)
          return css_var unless var_match

          "oklch(var(#{var_match[1]}) / #{alpha})"
        end

        # Returns a CSS variable reference for a theme color
        # DaisyUI 5 variables contain full oklch values like "oklch(45% .24 277.023)"
        # So we use var() directly
        def theme_color(name)
          css_var = CSS_VAR_MAP[name.to_s]
          return nil unless css_var

          "var(#{css_var})"
        end

        # Returns a theme color with alpha
        # We use color-mix for alpha since DaisyUI 5 vars have full oklch values
        def theme_color_with_alpha(name, alpha)
          css_var = CSS_VAR_MAP[name.to_s]
          return nil unless css_var

          "color-mix(in oklch, var(#{css_var}) #{(alpha * 100).to_i}%, transparent)"
        end
      end

      attr_reader :current, :use_theme_colors

      def initialize(use_theme_colors: true)
        @pointer = 0
        @use_theme_colors = use_theme_colors
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

      def colors
        @colors ||= if @use_theme_colors
                      theme_aware_colors
                    else
                      legacy_colors
                    end
      end

      # DaisyUI theme-aware colors (CSS variables)
      def theme_aware_colors
        THEME_COLORS.map { |name| self.class.theme_color(name) }
      end

      # Legacy hex colors (for backwards compatibility)
      def legacy_colors
        [
          '#22AA99', # turquoise
          '#3366CC', # blue
          '#DC3912', # red
          '#FF9900', # yellow
          '#109618', # green
          '#990099', # purple
          '#DD4477', # pink
          '#66AA00', # light_green
          '#E67300', # dark_yellow
          '#AAAA11' # olive
        ]
      end
    end
  end
end
