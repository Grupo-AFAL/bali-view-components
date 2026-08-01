# frozen_string_literal: true

module Bali
  module SideMenu
    module Trigger
      # The single control that opens a SideMenu.
      #
      # Before v3 the hamburger existed in three markups (Topbar, AppLayout's
      # fallback mobile chrome, Navbar::Burger) driven by two mechanisms — a
      # `<label>` flipping a hidden checkbox, and a Stimulus action dispatching
      # a window event. A `<label>` for a `display: none` checkbox is not
      # reachable by keyboard at all, which made the sidebar mouse-only on
      # mobile. All three now render this button.
      #
      # `aria-expanded` starts at "false" and is kept in sync by the
      # `side-menu-trigger` controller, which listens for the state event the
      # SideMenu broadcasts on open and close.
      class Component < ApplicationViewComponent
        BASE_CLASSES = "btn btn-ghost btn-sm"

        # @param menu_id [String] id of the SideMenu this opens — also its `aria-controls`
        # @param icon [String, nil] icon name; pass content instead for custom markup
        def initialize(menu_id: SideMenu::Component::DEFAULT_ID, icon: "menu", **options)
          @menu_id = menu_id
          @icon = icon
          @options = options
        end

        def call
          tag.button(type: "button", **button_options) do
            content.presence || default_icon
          end
        end

        private

        attr_reader :menu_id

        # `@options` is copied one level deeper than `dup` goes: `prepend_action`
        # writes into `options[:data]`, and that hash belongs to the caller.
        def button_options
          options = @options.merge(data: (@options[:data] || {}).dup)
          options = prepend_class_name(options, BASE_CLASSES)
          options = prepend_controller(options, "side-menu-trigger")
          options = prepend_action(options, "click->side-menu-trigger#toggle")
          options[:data]["side-menu-trigger-menu-id-value"] = menu_id
          options["aria-controls"] = menu_id
          options["aria-expanded"] = "false"
          options["aria-label"] = accessible_name(options)
          options
        end

        def accessible_name(options)
          options.delete(:"aria-label") || options["aria-label"] || t(".toggle")
        end

        def default_icon
          return if @icon.blank?

          render Bali::Icon::Component.new(@icon, size: :small)
        end
      end
    end
  end
end
