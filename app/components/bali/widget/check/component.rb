# frozen_string_literal: true

module Bali
  module Widget
    module Check
      # DOES IT PASS? — the whole card for a `CheckBase` widget.
      #
      # Like a ring, the icon REPLACES the number rather than decorating it, so
      # this does not inherit `Value` either.
      #
      # TERNARY, and that is the contract rather than an accident: `nil` means the
      # check has no answer yet and draws muted, which says something different
      # from a failing one. `Bali::BooleanIcon` owns all three states — the icon,
      # the colour, and the `sr-only` label without which colour is the only
      # thing separating pass from fail, which is WCAG 1.4.1.
      class Component < Card::Component
        private

        # The label is BOTH announced and printed: the icon carries the state,
        # the label carries what the state is about, so a screen reader hears
        # "4 blocking" rather than a bare "No".
        def headline
          return icon_with_label unless hero?

          safe_join([
            tag.div(icon, class: "flex justify-center"),
            tag.div(label, class: "stat-value mt-3 text-2xl")
          ])
        end

        def icon_with_label
          tag.div(class: "flex items-center gap-3") do
            safe_join([ icon, tag.span(label, class: "text-3xl font-semibold leading-none") ])
          end
        end

        # `scale` rather than a size argument: `BooleanIcon` draws one size, and a
        # hero tile wants it bigger than a header row does.
        def icon
          render Bali::BooleanIcon::Component.new(
            value: widget.state, label: label, class: hero? ? "scale-150" : "scale-125"
          )
        end

        def label = display_value
      end
    end
  end
end
