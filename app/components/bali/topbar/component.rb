# frozen_string_literal: true

module Bali
  module Topbar
    # Renders the topbar that sits inside the AppLayout's `with_topbar` slot.
    # Designed to align horizontally with the SideMenu's brand row (both 56px,
    # h-14) so the bottom border forms one continuous chrome divider.
    #
    # Composes 4 zones — brand (left, optional), search (center), actions
    # (right, many icon buttons), user_menu (far right). Pair with a sidebar
    # by passing the sidebar's `mobile_trigger_id` to render the hamburger on
    # small screens.
    class Component < ApplicationViewComponent
      BASE_CLASSES = "bali-topbar flex items-center gap-3 px-4 md:px-6 h-14 " \
                     "bg-base-100 border-b border-base-300"

      renders_one :brand
      renders_one :search
      renders_many :actions
      renders_one :user_menu

      # @param mobile_trigger_id [String, nil] When set, renders a hamburger label
      #   (lg:hidden) that toggles the matching sidebar checkbox. Defaults to the
      #   value of `Bali::SideMenu::Component::MOBILE_TRIGGER_ID` so the standard
      #   AppLayout pairing works without configuration. Pass `nil` to skip the
      #   hamburger — useful for layouts without a sidebar.
      def initialize(mobile_trigger_id: SideMenu::Component::MOBILE_TRIGGER_ID,
                     **options)
        @mobile_trigger_id = mobile_trigger_id
        @options = options
      end

      private

      attr_reader :mobile_trigger_id

      def container_classes
        class_names(BASE_CLASSES, @options[:class])
      end

      def container_attributes
        @options.except(:class)
      end

      def toggle_mobile_label
        I18n.t("bali.side_menu.toggle_mobile", default: "Toggle sidebar")
      end
    end
  end
end
