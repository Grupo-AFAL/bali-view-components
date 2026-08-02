# frozen_string_literal: true

module Bali
  # The one place a `.btn` is dressed.
  #
  # Three components render daisyUI's button — {Bali::Button}, {Bali::Link} in
  # button dress, and {Bali::DeleteLink} — and each used to carry its own table.
  # They disagreed on the axis daisyUI 5 is most careful to separate: Button
  # listed `outline` alongside `primary`, as if a border and a colour were the
  # same kind of thing, Link spelled it `style: :outline`, and DeleteLink offered
  # neither. Learning one of the three taught you nothing about the other two.
  #
  # daisyUI 5 splits a button's classes along three axes, and so does this:
  #
  #   variant:  the colour   btn-primary … btn-error, plus btn-ghost / btn-link
  #   style:    the fill     btn-outline, btn-soft
  #   size:     the scale    btn-xs … btn-xl
  #
  # They compose. `variant: :error, style: :outline, size: :sm` is a small red
  # bordered button, and all three components spell it exactly that way.
  #
  # `ghost` and `link` are styles in daisyUI's own docs, not colours. They stay
  # under `variant:` because that is where every call site in every host app
  # already writes them, and because they are mutually exclusive with a colour in
  # practice. The axis that moved is the one that was genuinely duplicated:
  # `outline` existed in both places under two different keywords.
  #
  # The literal class strings live here and nowhere else. Tailwind finds a class
  # by scanning source files for it verbatim; this file is inside the scanned
  # tree, but `"btn-#{variant}"` would be invisible to the scanner, which is why
  # the maps are written out longhand.
  module ButtonTaxonomy
    VARIANTS = {
      neutral: "btn-neutral",
      primary: "btn-primary",
      secondary: "btn-secondary",
      accent: "btn-accent",
      info: "btn-info",
      success: "btn-success",
      warning: "btn-warning",
      error: "btn-error",
      ghost: "btn-ghost",
      link: "btn-link"
    }.freeze

    STYLES = {
      outline: "btn-outline",
      soft: "btn-soft"
    }.freeze

    # `md` is the default size and has no class of its own: daisyUI's `.btn` is
    # already medium. It stays in the map so `size: :md` is a valid thing to
    # write rather than the one size that raises.
    SIZES = {
      xs: "btn-xs",
      sm: "btn-sm",
      md: "",
      lg: "btn-lg",
      xl: "btn-xl"
    }.freeze

    class << self
      # nil is how every optional axis is spelled, so it stays a no-op. Anything
      # else has to be a key: returning nil for an unknown value is how
      # `variant: :danger` survived two majors past its removal note, painting a
      # button with no colour at all and looking merely plain instead of broken.
      def variant!(component, value)
        lookup!(component, :variant, value, VARIANTS)
      end

      def style!(component, value)
        lookup!(component, :style, value, STYLES)
      end

      def size!(component, value)
        lookup!(component, :size, value, SIZES)
      end

      private

      def lookup!(component, param, value, table)
        return nil if value.nil?

        key = value.to_sym
        return table[key] if table.key?(key)

        raise ArgumentError, rejection_message(component, param, key, table)
      end

      def rejection_message(component, param, key, table)
        moved = moved_axis(param, key)
        return "#{component}: #{param}: #{key.inspect} is #{moved}." if moved

        replacement = Bali::Color::LEGACY[key]
        if replacement && VARIANTS.key?(replacement) && param == :variant
          return "#{component}: variant: #{key.inspect} is a Bulma name removed in v3. " \
                 "Use variant: #{replacement.inspect}."
        end

        "#{component}: unknown #{param} #{key.inspect}. " \
          "Valid: #{table.keys.map(&:inspect).join(', ')}."
      end

      # A value that is valid, just under a different keyword. Worth naming: the
      # alternative is telling someone their `outline` is unknown while the
      # library renders `btn-outline` on request.
      def moved_axis(param, key)
        return "a fill, not a colour. Use style: #{key.inspect}" if param == :variant &&
                                                                    STYLES.key?(key)
        return "a colour, not a fill. Use variant: #{key.inspect}" if param == :style &&
                                                                      VARIANTS.key?(key)

        nil
      end
    end
  end
end
