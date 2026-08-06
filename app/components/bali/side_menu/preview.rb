# frozen_string_literal: true

module Bali
  module SideMenu
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Basic sidebar with expandable groups (click to expand)
      # @param collapsible toggle
      def default(collapsible: false)
        render_with_template(
          template: "bali/side_menu/previews/default",
          locals: { collapsible: collapsible }
        )
      end

      # @param theme select { choices: [dark, ~] }
      # @label Dark chrome
      # A dark sidebar next to a light page — the shape every AFAL app
      # hand-rolls. `theme:` emits `data-theme` on the `<nav>`, and daisyUI
      # resolves its colour variables against the nearest ancestor that carries
      # one, so the rest of the page keeps the document's theme.
      #
      # ```erb
      # <%= render Bali::SideMenu::Component.new(current_path: request.path,
      #                                          theme: 'costa-norte-dark') do |menu| %>
      # ```
      #
      # The theme here is daisyUI's own `dark`, on purpose: **the gem ships the
      # mechanism, not the colours.** A brand's teal-and-gold chrome is not
      # something every app wants, so the token list to define your own is in
      # the [custom themes guide](../../../../docs/guides/custom-themes.md).
      #
      # Switch the param to `~` to compare against an unthemed sidebar. Open
      # **Configuration** in both: on a dark surface daisyUI's soft shadow is
      # invisible and a `base-100` panel is the same colour as the rail it opens
      # from, so a themed sidebar gets a lighter panel, a real border and a
      # stronger shadow. That fix comes with the theme; nothing changes for a
      # sidebar without one.
      def dark_chrome(theme: "dark")
        render_with_template(
          template: "bali/side_menu/previews/dark_chrome",
          locals: { theme: theme.to_s }
        )
      end

      # @label Expandable Groups
      # Nested menu items that expand/collapse on click using DaisyUI collapse component.
      # This is the default behavior.
      def expandable_groups
        render_with_template(template: "bali/side_menu/previews/expandable_groups")
      end

      # @label Dropdown Groups (Hover)
      # Nested menu items appear in a dropdown on hover instead of expanding inline.
      # Use `group_behavior: :dropdown` to enable this mode.
      def dropdown_groups
        render_with_template(template: "bali/side_menu/previews/dropdown_groups")
      end

      # @label With Menu Switcher
      # Menu switcher for switching between different application sections (e.g., different apps or projects).
      def with_menu_switcher
        render_with_template(template: "bali/side_menu/previews/with_menu_switcher")
      end

      # @label Active When (Nested Routes)
      # Use `active_when:` to keep an item highlighted on nested full-page routes that
      # `match:` alone misses — e.g. `/departments/1/merges/new`. It accepts a String
      # prefix, a Regexp, a lambda `->(current_path) { ... }`, or an Array of any of these,
      # and is OR-ed with the normal `match:` logic. Unlike `match: :starts_with`, it does
      # not light up unrelated siblings. This preview renders at
      # `/departments/1/merges/new`, so "Departments" stays active.
      def active_when
        render_with_template(template: "bali/side_menu/previews/active_when")
      end

      # @label Collapsible Sidebar
      # Sidebar that can collapse to icon-only mode. Click the toggle button to collapse/expand.
      # The collapse state is persisted in localStorage.
      def collapsible
        render_with_template(template: "bali/side_menu/previews/collapsible")
      end

      # @label Ecommerce Example
      # Full Nexus-style ecommerce sidebar with all features: collapsible, expandable groups,
      # menu sections, badges, and icons.
      def ecommerce
        render_with_template(template: "bali/side_menu/previews/ecommerce")
      end

      # @label With Icons
      # Menu items with Lucide icons
      def with_icons
        render_with_template(template: "bali/side_menu/previews/with_icons")
      end

      # @label With Badges
      # Menu items with notification badges. Section titles also support a badge via
      # `with_list(title:, badge:, badge_color:)` — see the "Pendientes" section header.
      def with_badges
        render_with_template(template: "bali/side_menu/previews/with_badges")
      end

      # @label With Bottom Items
      # Use `with_bottom_item` to pin items to the bottom of the sidebar — useful for user profile,
      # logout, or account settings links. Bottom items are fixed outside the scrollable area.
      # @param collapsible toggle
      def with_bottom_items(collapsible: false)
        render_with_template(
          template: "bali/side_menu/previews/with_bottom_items",
          locals: { collapsible: collapsible }
        )
      end

      # @label With Bottom Groups
      # Use `with_bottom_group` to add a collapsible dropdown at the bottom of the sidebar.
      # Useful for grouping configuration, profile, and logout items to save vertical space.
      # The dropdown opens **upward** so it doesn't overflow below the sidebar.
      # @param collapsible toggle
      def with_bottom_groups(collapsible: false)
        render_with_template(
          template: "bali/side_menu/previews/with_bottom_groups",
          locals: { collapsible: collapsible }
        )
      end

      # @label With Trigger (keyboard)
      # `Bali::SideMenu::Trigger::Component` is the single control that opens the sidebar —
      # the same button Topbar, AppLayout and Navbar::Burger render. It is a real `<button>`,
      # so the whole drawer is operable from the keyboard: Tab to it, Enter or Space to open,
      # Tab through the items, Escape to close, and focus returns to the button.
      # Narrow the viewport below `lg` to see the drawer; above it the sidebar is permanent.
      def with_trigger
        render_with_template(template: "bali/side_menu/previews/with_trigger")
      end
    end
  end
end
