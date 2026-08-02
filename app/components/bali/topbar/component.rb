# frozen_string_literal: true

module Bali
  module Topbar
    # Renders the topbar that sits inside the AppLayout's `with_topbar` slot.
    # Designed to align horizontally with the SideMenu's brand row — both
    # derive their height from the shared `--bali-chrome-height` variable so
    # the bottom border forms one continuous chrome divider.
    #
    # Composes 4 zones — brand (left, optional), search (center), actions
    # (right, many icon buttons), user_menu (far right).
    #
    # The root element is a `<header>`: it is the page's banner region, which
    # is what lets a screen-reader user jump to it by landmark. It is not
    # nested in `<main>` (AppLayout renders it as its sibling), so it maps to
    # `role="banner"` without an explicit role. Navbar is the page's `<nav>`,
    # so the two do not collide when a layout has both.
    class Component < ApplicationViewComponent
      BASE_CLASSES = "bali-topbar flex items-center gap-3 px-4 md:px-6 " \
                     "bali-chrome-height bg-base-100 border-b border-base-300"

      renders_one :brand
      renders_one :search
      renders_many :actions
      renders_one :user_menu

      # @param menu_id [String, nil] id of the SideMenu the hamburger opens.
      #   Renders a `Bali::SideMenu::Trigger::Component` (lg:hidden) wired to
      #   that sidebar. Defaults to `SideMenu::Component::DEFAULT_ID` so the
      #   standard AppLayout pairing works without configuration. Pass `nil` to
      #   skip the hamburger — useful for layouts without a sidebar.
      def initialize(menu_id: SideMenu::Component::DEFAULT_ID, **options)
        @menu_id = menu_id
        @options = options
      end

      private

      attr_reader :menu_id

      def container_classes
        class_names(BASE_CLASSES, @options[:class])
      end

      def container_attributes
        @options.except(:class)
      end
    end
  end
end
