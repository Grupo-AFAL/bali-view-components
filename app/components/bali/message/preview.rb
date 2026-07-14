# frozen_string_literal: true

module Bali
  module Message
    class Preview < ApplicationViewComponentPreview
      # @param color [Symbol] select [primary, success, danger, warning, info]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def default(color: :primary, size: :regular, style: nil)
        render Message::Component.new(title: "Header shortcut", size: size, color: color, style: style) do
          "Message Body"
        end
      end

      # @param color [Symbol] select [primary, success, danger, warning, info]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def custom_header(color: :primary, size: :regular, style: nil)
        render Message::Component.new(size: size, color: color, style: style) do |c|
          c.with_header do
            tag.h3 "Custom Header", class: "text-error text-lg font-bold"
          end

          "Message Body"
        end
      end

      # @param color [Symbol] select [primary, success, danger, warning, info]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def no_header(color: :primary, size: :regular, style: nil)
        render Message::Component.new(size: size, color: color, style: style) do
          "Message Body"
        end
      end

      # Live-region role. `role:` is the primary contract (allowlist:
      # alert, status, note). `polite:`/`assertive:` are convenience booleans:
      # `polite: true` maps to role `status`, `assertive: true` to role `alert`.
      # An explicit `role:` always wins over the booleans.
      #
      # @param role [Symbol] select [alert, status, note]
      # @param color [Symbol] select [primary, success, danger, warning, info]
      def live_region(role: :status, color: :info)
        render Message::Component.new(title: "Live region", role: role, color: color) do
          "Rendered with role=#{role}."
        end
      end

      # `polite: true` is sugar for role `status` (does not interrupt the
      # screen reader). Prefer this for non-urgent, informational messages.
      #
      # @param color [Symbol] select [primary, success, danger, warning, info]
      def polite(color: :info)
        render Message::Component.new(title: "Polite", polite: true, color: color) do
          "Announced politely (role=status)."
        end
      end

      # `assertive: true` is sugar for role `alert` (interrupts the screen
      # reader). Use for urgent messages such as errors.
      #
      # @param color [Symbol] select [primary, success, danger, warning, info]
      def assertive(color: :danger)
        render Message::Component.new(title: "Assertive", assertive: true, color: color) do
          "Announced assertively (role=alert)."
        end
      end

      # A dismissible message renders an integrated close button wired to the
      # `message` Stimulus controller, which removes the alert on click.
      #
      # @param color [Symbol] select [primary, success, danger, warning, info]
      # @param style [Symbol] select [~, soft, outline, dash]
      def dismissible(color: :primary, style: nil)
        render Message::Component.new(title: "Dismissible", dismissible: true, color: color, style: style) do
          "Click the ✕ to dismiss this message."
        end
      end

      # Passing `dismiss_id:` persists the dismissed state in localStorage under
      # a namespaced key, so the message stays hidden on future page loads.
      #
      # @param color [Symbol] select [primary, success, danger, warning, info]
      def dismissible_persistent(color: :info)
        render Message::Component.new(
          title: "Persistent dismiss",
          dismissible: true,
          dismiss_id: "preview-welcome-banner",
          color: color
        ) do
          "Dismiss me and reload — I will stay hidden."
        end
      end

      # @label All Combinations
      # Shows all message variants: colors, sizes, styles, and a full color x style matrix.
      def all_combinations
        render_with_template
      end
    end
  end
end
