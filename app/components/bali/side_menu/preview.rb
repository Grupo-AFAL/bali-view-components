# frozen_string_literal: true

module Bali
  module SideMenu
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Basic sidebar with expandable groups (click to expand)
      # @param collapsible toggle
      def default(collapsible: false)
        render_with_template(
          template: 'bali/side_menu/previews/default',
          locals: { collapsible: collapsible }
        )
      end

      # @label Expandable Groups
      # Nested menu items that expand/collapse on click using DaisyUI collapse component.
      # This is the default behavior.
      def expandable_groups
        render_with_template(template: 'bali/side_menu/previews/expandable_groups')
      end

      # @label Dropdown Groups (Hover)
      # Nested menu items appear in a dropdown on hover instead of expanding inline.
      # Use `group_behavior: :dropdown` to enable this mode.
      def dropdown_groups
        render_with_template(template: 'bali/side_menu/previews/dropdown_groups')
      end

      # @label With Menu Switcher
      # Menu switcher for switching between different application sections (e.g., different apps or projects).
      def with_menu_switcher
        render_with_template(template: 'bali/side_menu/previews/with_menu_switcher')
      end

      # @label Collapsible Sidebar
      # Sidebar that can collapse to icon-only mode. Click the toggle button to collapse/expand.
      # The collapse state is persisted in localStorage.
      def collapsible
        render_with_template(template: 'bali/side_menu/previews/collapsible')
      end

      # @label Ecommerce Example
      # Full Nexus-style ecommerce sidebar with all features: collapsible, expandable groups,
      # menu sections, badges, and icons.
      def ecommerce
        render_with_template(template: 'bali/side_menu/previews/ecommerce')
      end

      # @label With Icons
      # Menu items with Lucide icons
      def with_icons
        render_with_template(template: 'bali/side_menu/previews/with_icons')
      end

      # @label With Badges
      # Menu items with notification badges
      def with_badges
        render_with_template(template: 'bali/side_menu/previews/with_badges')
      end

      # @label With Bottom Items
      # Use `with_bottom_item` to pin items to the bottom of the sidebar — useful for user profile,
      # logout, or account settings links. Bottom items are fixed outside the scrollable area.
      # @param collapsible toggle
      def with_bottom_items(collapsible: false)
        render_with_template(
          template: 'bali/side_menu/previews/with_bottom_items',
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
          template: 'bali/side_menu/previews/with_bottom_groups',
          locals: { collapsible: collapsible }
        )
      end
    end
  end
end
