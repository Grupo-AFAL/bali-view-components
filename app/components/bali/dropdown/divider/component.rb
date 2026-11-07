# frozen_string_literal: true

module Bali
  module Dropdown
    module Divider
      # A rule between two groups of items.
      #
      # It is the `<li>` itself, not something inside the `<li role="none">` the Dropdown wraps
      # every other item in: daisyUI draws the rule on an empty `<li>` of a `.menu`
      # (`.menu :where(li:empty)`), and any child would stop it matching. As a `separator`
      # it is one of the three children a `role="menu"` allows, and the controller, which walks
      # `[role^="menuitem"]`, never focuses it.
      class Component < ApplicationViewComponent
        def initialize(**options)
          @options = options.reverse_merge(role: "separator")
        end

        def authorized?
          true
        end

        def menu_divider?
          true
        end

        def call
          tag.li(**@options)
        end
      end
    end
  end
end
