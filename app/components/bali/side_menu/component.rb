# frozen_string_literal: true

module Bali
  module SideMenu
    class Component < ApplicationViewComponent
      # Group behavior modes for nested menu items
      # - :expandable - Click to expand/collapse using DaisyUI collapse (default)
      # - :dropdown - Show submenu in dropdown on hover
      GROUP_BEHAVIORS = %i[expandable dropdown].freeze

      renders_many :menu_switches, Bali::SideMenu::MenuSwitch::Component

      # Brand slot — renders rich content (logo + text, just an icon, custom HTML)
      # in the chrome row above the menu switcher. Falls back to the `brand:`
      # parameter when the slot is not set, so existing string usage keeps working.
      renders_one :brand

      renders_many :bottom_items, Item::Component.renderable

      renders_many :bottom_groups,
                   lambda { |name:, icon: nil, **options|
                     BottomGroup::Component.new(
                       name: name,
                       icon: icon,
                       current_path: @current_path,
                       **options
                     )
                   }

      renders_many :lists, ->(title: nil, **options) do
        List::Component.new(
          title: title,
          current_path: @current_path,
          group_behavior: @group_behavior,
          **options
        )
      end

      # The id every trigger points at through `aria-controls`, and the id the
      # `side-menu-trigger` controller addresses its open/close events to. One
      # sidebar per page is the norm, so a fixed default keeps Topbar,
      # AppLayout and Navbar::Burger wired without configuration.
      DEFAULT_ID = "side-menu"

      # @param current_path [String] The current request path for active state detection
      # @param id [String] DOM id — the target of every trigger's `aria-controls`
      # @param fixed [Boolean] Fixed to viewport (true) or inline flow (false). Default: true
      # @param collapsible [Boolean] Whether the sidebar can collapse to icon-only mode
      # @param group_behavior [Symbol] How nested items behave - :expandable or :dropdown
      # @param brand [String] Optional brand name shown in the header (e.g., "ACME")
      # @param aria_label [String] Accessible name of the <nav> landmark
      # @param theme [String, Symbol, nil] A daisyUI theme name, emitted as
      #   `data-theme` on the `<nav>`. This is how an app gives the sidebar a
      #   different skin from the page it sits next to — the dark chrome over a
      #   light content area that every AFAL app hand-rolls. The theme itself is
      #   the host's: its colours are brand, so the gem ships the mechanism and
      #   documents the token list (see docs/guides/custom-themes.md), not the
      #   values.
      # @param reveal_current [Boolean] Scroll the menu so the item for the current page is
      #   in view. On by default (#1099): every navigation re-renders the sidebar and its
      #   scroll returns to the top, so in a menu taller than the screen the active item
      #   lands out of view and the menu stops answering "where am I". It only ever moves
      #   the menu's own scroll, never the page's, and it does nothing when the item is
      #   already visible. Pass `false` for a sidebar whose scroll position is yours.
      def initialize(current_path:, id: DEFAULT_ID, fixed: true, collapsible: false,
                     group_behavior: :expandable, reveal_current: true,
                     brand: nil, aria_label: nil, theme: nil, **options)
        @theme = theme.presence&.to_s
        @current_path = current_path
        @id = id
        @fixed = fixed
        @collapsible = collapsible
        @group_behavior = GROUP_BEHAVIORS.include?(group_behavior) ? group_behavior : :expandable
        @reveal_current = reveal_current
        @brand = brand
        @aria_label = aria_label
        @options = options
      end

      attr_reader :id

      def fixed?
        @fixed
      end

      def collapsible?
        @collapsible
      end

      def expandable_groups?
        @group_behavior == :expandable
      end

      def dropdown_groups?
        @group_behavior == :dropdown
      end

      def container_classes
        class_names(
          "side-menu-component",
          { "side-menu-component--fixed" => @fixed },
          { "side-menu-component--inline" => !@fixed },
          @options[:class]
        )
      end

      # `multiple_menus?` joins the two states that already asked for the controller
      # because the module switcher now needs it too: a `<details>` closes on its own
      # `<summary>` and on nothing else, so click-outside and Escape are JavaScript
      # (#830). Without this a sidebar that is neither collapsible nor fixed — which is
      # exactly what the switcher preview composes — got no controller at all and the
      # panel stayed open over the page.
      #
      # `@reveal_current` joins the list for the same reason and it is the same mistake
      # twice (#1099): the menu scrolls whenever it is taller than its box, which has
      # nothing to do with being pinned or collapsible, so an inline sidebar would have
      # been the one case the reveal silently skipped.
      def container_data
        data = (@options[:data] || {}).dup
        data[:controller] = class_names(
          data[:controller],
          { "side-menu" => @collapsible || @fixed || @reveal_current || multiple_menus? }
        )
        data[:side_menu_collapsible_value] = @collapsible
        data[:side_menu_fixed_value] = @fixed
        # Emitido solo cuando está apagado: el default del controller ya es `true`, y un
        # `data-side-menu-reveal-current-value="true"` en cada sidebar es ruido que además
        # invita a leerlo como si fuera el interruptor.
        data[:side_menu_reveal_current_value] = false unless @reveal_current
        data
      end

      def container_options
        opts = @options.except(:class, :data)
        opts[:id] = @id
        opts[:class] = container_classes
        opts[:data] = container_data
        opts["aria-label"] = aria_label
        # daisyUI resolves its colour variables against the nearest ancestor
        # carrying `data-theme`, so putting it here — and not on <html> — is the
        # whole of "the sidebar is dark and the page is not".
        opts["data-theme"] = @theme if @theme
        # A pinned sidebar starts closed and off-screen, so it starts out of the
        # tab order too. SideMenuController takes ownership on connect and drops
        # the attribute immediately at desktop widths, where the sidebar is
        # permanent chrome rather than a drawer.
        opts[:inert] = true if @fixed
        opts
      end

      # Menu switch helpers
      def authorized_menus
        @authorized_menus ||= menu_switches.select(&:authorized?)
      end

      def single_menu?
        authorized_menus.size == 1
      end

      def multiple_menus?
        authorized_menus.size > 1
      end

      def active_menu
        authorized_menus.find(&:active?) || authorized_menus.first
      end

      # True when EITHER the brand slot is set OR the `brand:` text param is present.
      # Overrides the slot's auto-generated `brand?` so the chrome row renders
      # whichever path the consumer used.
      def brand_present?
        brand? || @brand.present?
      end

      def aria_label
        @aria_label.presence || I18n.t("bali_view.side_menu.label")
      end

      # Translated aria-label for the mobile close button
      def close_label
        I18n.t("bali_view.side_menu.close")
      end

      # Translated title for collapse button
      def collapse_label
        I18n.t("bali_view.side_menu.collapse")
      end

      # Translated title for expand button
      def expand_label
        I18n.t("bali_view.side_menu.expand")
      end
    end
  end
end
