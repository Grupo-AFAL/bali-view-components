# frozen_string_literal: true

module Bali
  module Alert
    class Preview < ApplicationViewComponentPreview
      # @param color [Symbol] select [neutral, info, success, warning, error]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def default(color: :info, size: :regular, style: nil)
        render Alert::Component.new(title: "Header shortcut", size: size, color: color, style: style) do
          "Alert body"
        end
      end

      # `icon: true` picks the icon that goes with the colour; a string names one
      # directly. Left out, an alert has no icon — which is what every inline
      # `Bali::Message` looked like in v2.
      #
      # @param color [Symbol] select [neutral, info, success, warning, error]
      # @param icon text
      def with_icon(color: :success, icon: "true")
        render Alert::Component.new(title: "With icon", color: color, icon: icon == "true" || icon) do
          "The icon defaults to the one that matches the colour."
        end
      end

      # @param color [Symbol] select [neutral, info, success, warning, error]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def custom_header(color: :info, size: :regular, style: nil)
        render Alert::Component.new(size: size, color: color, style: style) do |c|
          c.with_header do
            tag.h3 "Custom Header", class: "text-error text-lg font-bold"
          end

          "Alert body"
        end
      end

      # @param color [Symbol] select [neutral, info, success, warning, error]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def no_header(color: :info, size: :regular, style: nil)
        render Alert::Component.new(size: size, color: color, style: style) do
          "Alert body"
        end
      end

      # Live-region role. Without `role:` the role comes from the colour: `alert`
      # (assertive, interrupts the screen reader) for `error`, `status` (polite)
      # for everything else. `polite:`/`assertive:` are convenience booleans; an
      # explicit `role:` always wins over them, and an unknown role raises.
      #
      # @param role [Symbol] select [alert, status, note]
      # @param color [Symbol] select [neutral, info, success, warning, error]
      def live_region(role: :status, color: :info)
        render Alert::Component.new(title: "Live region", role: role, color: color) do
          "Rendered with role=#{role}."
        end
      end

      # `polite: true` is sugar for role `status` (does not interrupt the
      # screen reader). Prefer this for non-urgent, informational messages.
      #
      # @param color [Symbol] select [neutral, info, success, warning, error]
      def polite(color: :info)
        render Alert::Component.new(title: "Polite", polite: true, color: color) do
          "Announced politely (role=status)."
        end
      end

      # `assertive: true` is sugar for role `alert` (interrupts the screen
      # reader). Use for urgent messages such as errors.
      #
      # @param color [Symbol] select [neutral, info, success, warning, error]
      def assertive(color: :error)
        render Alert::Component.new(title: "Assertive", assertive: true, color: color) do
          "Announced assertively (role=alert)."
        end
      end

      # A closable alert renders an integrated close button wired to the `alert`
      # Stimulus controller, which removes it on click.
      #
      # @param color [Symbol] select [neutral, info, success, warning, error]
      # @param style [Symbol] select [~, soft, outline, dash]
      def closable(color: :info, style: nil)
        render Alert::Component.new(title: "Closable", closable: true, color: color, style: style) do
          "Click the ✕ to close this alert."
        end
      end

      # Passing `dismiss_id:` persists the dismissed state in localStorage under
      # a namespaced key, so the alert stays hidden on future page loads.
      #
      # @param color [Symbol] select [neutral, info, success, warning, error]
      def closable_persistent(color: :info)
        render Alert::Component.new(
          title: "Persistent dismiss",
          closable: true,
          dismiss_id: "preview-welcome-banner",
          color: color
        ) do
          "Dismiss me and reload — I will stay hidden."
        end
      end

      # `duration:` closes the alert on its own after that many milliseconds. It is
      # what makes a `Bali::Toast` a toast, and it works on an inline alert too.
      #
      # @param color [Symbol] select [neutral, info, success, warning, error]
      # @param duration number
      def timed(color: :success, duration: 5000)
        render Alert::Component.new(title: "Timed", color: color, duration: duration, closable: true) do
          "Closes on its own after #{duration}ms."
        end
      end

      # @label All Combinations
      # Shows all alert variants: colors, sizes, styles, and a full color x style matrix.
      # @label With block content
      # @param color select [info, success, warning, error, neutral]
      # A title over a list of records with links — the alert #1120 was reported on.
      # The body is a `<div>`, so a `<ul>` or a `<p>` inside it is valid HTML; it used
      # to be a `<span>`, which browsers painted the same and validators rejected.
      def with_block_content(color: :warning)
        render_with_template(locals: { color: color.to_sym })
      end

      # @label Tinted styles, with a body
      # @param color select [info, success, warning, error]
      # @param style select [soft, outline, dash]
      # The case #1126 was reported on: a soft warning with a title, a paragraph,
      # a list and links. daisyUI paints the text of soft, outline and dash in the
      # accent colour — over a tint of that same accent, or over the bare page —
      # which is light-on-light on a light theme. Bali's override
      # (alert/daisyui-overrides.css) gives the text a colour that contrasts while
      # the icon and the border keep the accent. Switch the theme to afal-dark to
      # see the same rule hold where the `*-content` token would not have.
      def soft_block(color: :warning, style: :soft)
        render_with_template(locals: { color: color.to_sym, style: style.to_sym })
      end

      def all_combinations
        render_with_template
      end
    end
  end
end
