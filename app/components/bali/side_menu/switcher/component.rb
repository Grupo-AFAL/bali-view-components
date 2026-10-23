# frozen_string_literal: true

module Bali
  module SideMenu
    module Switcher
      # One selector of the side menu's stack: a `<details>` dropdown with the active
      # option on its trigger and the others in its panel. The module switcher is the
      # first of the stack (built from `menu_switches`); every `switcher` slot adds
      # one more under it, for a menu subdivided in levels — module, then context
      # (the integration, the branch, the project being viewed).
      #
      # An option navigates with a link by default. `method:` other than `:get`
      # makes it a form (`button_to`): a selector that changes state on the server
      # must not be a link, or Turbo's hover prefetch would change it on hover.
      class Component < ApplicationViewComponent
        renders_many :options, Bali::SideMenu::MenuSwitch::Component

        # @param label [String, nil] Small heading above the trigger ("Integración")
        # @param accent [Boolean] Primary-coloured trigger, for the selector a screen
        #   depends on
        # @param menus [Array, nil] Ready-made options; the module switcher passes its
        #   `menu_switches` here instead of re-declaring them as slots
        def initialize(label: nil, accent: false, menus: nil)
          @label = label
          @accent = accent
          @menus = menus
        end

        def entries
          @entries ||= @menus || options.select(&:authorized?)
        end

        def active_entry
          entries.find(&:active?) || entries.first
        end

        # A context selector shows its one option as where you are; the module
        # switcher, which passes `menus:`, already decides itself to render with two.
        def render?
          entries.any?
        end

        private

        attr_reader :label

        def wrapper_classes
          class_names("menu-switcher mb-3", "menu-switcher--accent": @accent)
        end

        def trigger_classes
          class_names(
            "menu-switcher-trigger tooltip tooltip-right rounded-box flex w-full items-center gap-2 border " \
            "cursor-pointer list-none [&::-webkit-details-marker]:hidden",
            @accent ? "border-primary/50 bg-base-content/6 px-2 py-3 hover:bg-base-content/10" : "border-base-300 hover:bg-base-content/8 p-2"
          )
        end

        def link?(entry)
          entry.http_method == :get
        end
      end
    end
  end
end
