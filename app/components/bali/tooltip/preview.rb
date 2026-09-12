# frozen_string_literal: true

module Bali
  module Tooltip
    class Preview < ApplicationViewComponentPreview
      # @param placement select { choices: [top, bottom, left, right] }
      # @param trigger_event select { choices: [mouseenter focusin, click, manual] }
      #
      # Fully qualified on purpose: Lookbook evaluates a `@param`'s default expression in the
      # preview class's own context rather than in the method body, so `Module.nesting` is
      # empty there and a bare `Component::DEFAULT_TRIGGER` is a 500 on the preview URL.
      def default(placement: :top, trigger_event: Bali::Tooltip::Component::DEFAULT_TRIGGER)
        render Tooltip::Component.new(placement: placement, trigger_event: trigger_event) do |c|
          c.with_trigger { tag.span "Hover me", class: "link link-primary" }
          tag.p "Hi, this is the tooltip content"
        end
      end

      # Markup content
      # ---------------
      # The balloon is built to carry HTML — the template hands tippy a `<template>` and
      # `allowHTML` is on — so content with no plain text in it at all is a supported shape,
      # not a mistake. Both balloons here hold a single element and nothing else. Neither
      # existed before #788: the empty check asked whether there was text, so an image or an
      # `<svg>` on its own read as nothing and the controller returned before building.
      def markup_content
        render_with_template
      end

      # Shows tooltip behavior when content is empty (no tooltip appears)
      def empty_tooltip
        render Tooltip::Component.new do |c|
          c.with_trigger { tag.span "Link without tooltip", class: "link" }
        end
      end

      # Common pattern: help icon with tooltip explanation
      def help_tip
        render Tooltip::Component.new(class: "help-tip") do |c|
          c.with_trigger do
            tag.span "?",
                     class: "w-6 h-6 rounded-full border border-neutral flex items-center justify-center text-sm"
          end
          tag.p "Hi, this is the help tip content"
        end
      end

      def all_placements
        render_with_template
      end

      # Keyboard reach
      # ---------------
      # The two shapes a trigger slot comes in, side by side, both reachable with Tab alone.
      # On the left the caller supplied the focusable control, so the wrapper stays out of
      # the tab order and the balloon opens off the button's own focus (`focusin`, which
      # bubbles — tippy's `focus` only fires for the wrapper itself and never did).
      # On the right the slot is plain text, so the controller makes the wrapper the tab
      # stop; without it that tooltip has no keyboard route at all.
      def keyboard_reach
        render_with_template
      end

      # Both triggers sit inside an `overflow-hidden` box. Since #992 the
      # default (`:body`) portals the balloon out and escapes the clip;
      # `append_to: :parent` is the opt-in that keeps the balloon in place —
      # and shows exactly the clipping that made `:body` the default.
      def escapes_overflow
        render_with_template
      end
    end
  end
end
