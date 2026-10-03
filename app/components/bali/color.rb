# frozen_string_literal: true

module Bali
  # The one place a `color:` keyword is resolved.
  #
  # Seven components used to carry seven private colour maps that disagreed on
  # which names existed and on what a name meant — which is how `Bali::Heatmap`
  # ended up painting hardcoded hex that ignored the theme while `Bali::Chart`,
  # one component over, painted daisyUI variables. They all name their colours
  # from the palette below now, and validate them here.
  #
  # Two keywords, and only two:
  #
  #   color:        a symbol from NAMES. Follows the daisyUI theme.
  #   custom_color: a hex string. The escape hatch: the hex itself never follows the
  #                 theme, though `soft` mixes it into the theme's ink.
  #
  # What this module does NOT do is build Tailwind class names. `"badge-#{name}"`
  # would be invisible to Tailwind's source scanner, so every class a component
  # can emit has to appear in that component's own file as a literal string. The
  # per-component maps that remain are those literal tables; what is shared is
  # their key set (NAMES) and the rejection of anything outside it.
  module Color
    # daisyUI's semantic colours, in daisyUI's own order.
    SEMANTIC = %i[neutral primary secondary accent info success warning error].freeze

    # daisyUI's name for "no colour of its own". There is no `--color-ghost`, so
    # a component either has a class for it (`badge-ghost`) or falls back to the
    # theme's own foreground.
    GHOST = :ghost

    NAMES = [ *SEMANTIC, GHOST ].freeze

    # What `:ghost` and `:neutral` resolve to when a component needs a colour *value*
    # rather than a class — a gradient stop, an inline style.
    GHOST_VARIABLE = "--color-base-content"

    # The order a component cycles through when one call site needs more than one
    # colour, e.g. the slices of a pie chart. `neutral` is left out: it is the
    # colour of furniture, and named for data it paints as base-content anyway.
    #
    # Not daisyUI's order: `afal`'s primary and secondary differ in hue alone (ΔL 0.005),
    # and `afal-dark`'s measured ΔE_OK 0.003 apart under deuteranopia. In this order no
    # two neighbouring theme colours, the last and the first included, come closer than
    # 0.06 under protanopia, deuteranopia or tritanopia in the six themes; painted as a
    # bar's half-opaque fill, about 0.03 (#1281).
    CYCLE = %i[primary accent secondary success warning info error].freeze

    # #rgb, #rgba, #rrggbb, #rrggbbaa. Anything else is not something we can drop
    # into a style attribute without guessing what the caller meant.
    HEX = /\A#(?:\h{3,4}|\h{6}|\h{8})\z/

    # The Bulma names v1 and v2 also accepted, mapped to what replaced them. Kept
    # as data so a call site that never migrated is told which value to write
    # instead of being handed the whole list of valid ones.
    LEGACY = {
      danger: :error,
      link: :primary,
      black: :neutral,
      dark: :neutral,
      light: :ghost,
      white: :ghost
    }.freeze

    GRADIENT_STEPS = 10

    class << self
      # nil is how every optional colour is spelled, so it stays a no-op.
      # Anything else has to be a name: silently dropping an unknown value is how
      # the Bulma names survived two majors past their removal note.
      def name!(component, value, param: :color, allowed: NAMES)
        return nil if value.nil?

        key = value.to_sym
        return key if allowed.include?(key)

        raise ArgumentError, rejection_message(component, param, key, allowed)
      end

      def hex!(component, value, param: :custom_color)
        return nil if value.blank?
        return value if hex?(value)

        raise ArgumentError,
              "#{component}: #{param} #{value.inspect} is not a hex colour " \
              "(#rgb or #rrggbb). Semantic names belong in `color:`."
      end

      def hex?(value)
        value.is_a?(String) && value.match?(HEX)
      end

      # A colour as a CSS value: a theme variable for a name, the string itself
      # for a hex or for anything already written as CSS.
      def css(color)
        return color if css_value?(color)
        return "var(#{GHOST_VARIABLE})" if page_ink?(color)

        "var(--color-#{color})"
      end

      def css_value?(color)
        color.is_a?(String) && (color.start_with?("#") || color.include?("("))
      end

      # Alpha through color-mix, not through an alpha channel. daisyUI 5 stores a
      # whole `oklch(45% .24 277)` in `--color-primary`, so `oklch(var(--color-primary) / .5)`
      # — the form this repo used before — is not valid CSS at all.
      def with_alpha(color, percent)
        "color-mix(in oklch, #{css(color)} #{percent}%, transparent)"
      end

      # `text-soft-*` (bali/utilities.css) as a value, for a colour no utility can name: a hex.
      # The hex itself over its own tint read 1.99:1 for an amber on the light themes and 2.14
      # for a violet on `dark` — the two ends of the Bali::Status hexes costa-norte hands to
      # StatCard's `custom_color:`.
      def soft(color)
        "color-mix(in oklab, #{css(color)} 40%, var(--color-base-content))"
      end

      # A ramp from transparent to the colour, for a heatmap or any other
      # intensity scale. Ten stops at 0%, 10% … 90%.
      def gradient(color, size: GRADIENT_STEPS)
        (0...size).map { |step| with_alpha(color, step * (100 / size)) }
      end

      # The cycle rotated so `color` leads it. Used where one call site names a
      # base colour but the component still needs a full palette. A name outside
      # the cycle (`:neutral`, `:ghost`) leads it instead of being ignored.
      def cycle_from(color)
        return CYCLE.dup if color.blank?

        name = color.to_sym
        index = CYCLE.index(name)
        index ? CYCLE.rotate(index) : [ name, *CYCLE ]
      end

      private

      # `:neutral` asked for as a value — a chart bar, a heatmap cell — paints with the ink: a
      # dark theme's neutral is a fill and does not read on the page, and base-content is the
      # same colour on Bali's light themes.
      def page_ink?(color)
        [ GHOST, :neutral ].include?(color.to_sym)
      end

      def rejection_message(component, param, key, allowed)
        replacement = LEGACY[key]

        if replacement && allowed.include?(replacement)
          "#{component}: #{param} #{key.inspect} is a Bulma name removed in v3. " \
            "Use #{param}: #{replacement.inspect}."
        else
          "#{component}: unknown #{param} #{key.inspect}. " \
            "Valid: #{allowed.map(&:inspect).join(', ')}."
        end
      end
    end
  end
end
