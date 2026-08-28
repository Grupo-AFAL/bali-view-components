# frozen_string_literal: true

module Bali
  module Widget
    module Value
      # A FIGURE, AND NOTHING ELSE — the whole card for a `ValueBase` widget.
      #
      # The simplest of the five: one region filled, no chart, no rows. Its
      # `empty_state?` still reaches the breakdown region at `medium` and above,
      # which is why the base renders that region rather than this class.
      class Component < Card::Component
        private

        # `tabular-nums` because a figure that changes on refresh should not
        # shift the characters beside it.
        def headline
          tag.div(display_value, class: figure_classes)
        end

        def figure_classes
          class_names(
            "tabular-nums",
            hero? ? "stat-value text-4xl" : "text-3xl font-semibold leading-none",
            muted? ? "text-base-content/30" : "text-base-content"
          )
        end
      end
    end
  end
end
