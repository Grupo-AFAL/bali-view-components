# frozen_string_literal: true

module Bali
  module Gantt
    # Color system of the Gantt (#704) — the EXACT formulas of the React
    # island's ganttColors.js, so the server-rendered `:static` mode and the
    # phase-2 island are visually identical bar for bar. Every color is a hash
    # { solid:, fill:, border:, text: }: bar body (fill+border), progress
    # overlay (solid) and legend/badges (solid/text) share one treatment.
    #
    # Values are CSS strings over daisyUI 5 theme variables
    # (`color-mix(in oklch, var(--color-*) N%, transparent)`), meant for INLINE
    # styles — computed colors never go into interpolated Tailwind classes,
    # which v4 purges.
    module Colors
      # Default status → daisyUI color variable map (ganttColors.js STATUS_VAR).
      # nil = neutral (gray) treatment. Hosts with other status vocabularies
      # pass their own catalog to the component instead of patching this.
      DEFAULT_STATUS_VARS = {
        "backlog" => nil,
        "in_progress" => "--color-info",
        "ready_for_review" => "--color-warning",
        "complete" => "--color-success",
        "cancelled" => nil
      }.freeze

      module_function

      # ganttColors.js neutralColor().
      def neutral
        {
          solid: "color-mix(in oklch, var(--color-base-content) 42%, transparent)",
          fill: "color-mix(in oklch, var(--color-base-content) 10%, transparent)",
          border: "color-mix(in oklch, var(--color-base-content) 30%, transparent)",
          text: "color-mix(in oklch, var(--color-base-content) 62%, transparent)"
        }
      end

      # ganttColors.js varColor(): color from a daisyUI variable (e.g.
      # "--color-info"). fill/border derive by color-mix so no opaque token the
      # theme might not define is needed.
      def var_color(css_var)
        color = "var(#{css_var})"
        {
          solid: color,
          fill: "color-mix(in oklch, #{color} 16%, transparent)",
          border: "color-mix(in oklch, #{color} 50%, transparent)",
          text: color
        }
      end

      # ganttColors.js statusColor(): daisyUI variable when the status maps to
      # one, neutral otherwise.
      def status_color(status, vars: DEFAULT_STATUS_VARS)
        var = vars[status.to_s]
        var ? var_color(var) : neutral
      end

      # ganttColors.js hueColor(): free-hue color (assignee/phase/priority
      # modes land in phase 2; the formula is ported now for parity).
      def hue_color(hue)
        return neutral if hue.nil?

        {
          solid: "oklch(0.62 0.15 #{hue})",
          fill: "oklch(0.62 0.15 #{hue} / 0.15)",
          border: "oklch(0.6 0.15 #{hue} / 0.5)",
          text: "oklch(0.46 0.16 #{hue})"
        }
      end

      # ganttColors.js hashHue(): stable 0..359 hue from a string (same
      # algorithm, so Ruby and JS color the same assignee identically).
      def hash_hue(value)
        value.to_s.each_char.reduce(0) { |hash, char| (hash * 31 + char.ord) % 360 }
      end
    end
  end
end
