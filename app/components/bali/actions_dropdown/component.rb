# frozen_string_literal: true

module Bali
  module ActionsDropdown
    # A Bali::Dropdown with its trigger already chosen: the ⋯ button of a table row.
    #
    # It used to be a second implementation of the same menu, and the two had drifted in
    # every direction that matters. It reimplemented `with_item` almost line for line, kept
    # its own `ALIGNMENTS` / `DIRECTIONS` / `WIDTHS` tables against Dropdown's single
    # `align:` and boolean `wide:`, and — the part that hurt — carried none of Dropdown's
    # accessibility: no `data-controller="dropdown"`, so no arrow keys and no Escape; no
    # `role="menu"` on the list; an `aria-expanded` that was never emitted at all, let alone
    # kept in sync. It opened on daisyUI's `:focus-within` and that was the whole of it.
    #
    # What is below this line is now the entire difference between the two components.
    class Component < Dropdown::Component
      DEFAULT_ICON = "ellipsis-h"

      # @param icon [String, Symbol] the trigger's icon. Every other keyword is
      #   Bali::Dropdown::Component's, including `popover:`, which is what a menu inside a
      #   scrollable table needs.
      def initialize(icon: DEFAULT_ICON, **options)
        @icon = icon
        super(**options)
      end

      # Absolute key, for the reason Dropdown::Component::MENU_LABEL_KEY names.
      TRIGGER_LABEL_KEY = "bali_view.dropdown.actions_trigger_label"

      # The old trigger painted `text-neutral-600 hover:text-neutral-800` over the ghost
      # button — Tailwind greys, not theme tokens, so the ⋯ stayed dark grey on a dark
      # theme. `btn-ghost` already colours itself from the theme; the override is gone.
      #
      # The icon is rendered into a local first and the block merely returns it. A block
      # that calls `render` itself comes back EMPTY here: `capture` prefers the output
      # buffer, a nested `render_in` does not write to the buffer `capture` swapped in, and
      # the returned string is discarded — measured, the trigger came out as an empty
      # `<div class="btn btn-ghost btn-circle btn-sm">`.
      def default_trigger
        icon = render(Bali::Icon::Component.new(@icon))

        render(Dropdown::Trigger::Component.new(
                 variant: :icon,
                 class: "btn-sm",
                 "aria-label": t(TRIGGER_LABEL_KEY)
               )) { icon }
      end
    end
  end
end
