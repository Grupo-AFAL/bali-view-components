# frozen_string_literal: true

module Bali
  module SideMenu
    class Component < ApplicationViewComponent
      # Group behavior modes for nested menu items
      # - :expandable - Click to expand/collapse using DaisyUI collapse (default)
      # - :dropdown - Show submenu in dropdown on hover
      GROUP_BEHAVIORS = %i[expandable dropdown].freeze

      renders_many :menu_switches, Bali::SideMenu::MenuSwitch::Component

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

      MOBILE_TRIGGER_ID = "side-menu-mobile-trigger"

      # @param current_path [String] The current request path for active state detection
      # @param fixed [Boolean] Fixed to viewport (true) or inline flow (false). Default: true
      # @param collapsible [Boolean] Whether the sidebar can collapse to icon-only mode
      # @param group_behavior [Symbol] How nested items behave - :expandable or :dropdown
      # @param brand [String] Optional brand name shown in the header (e.g., "ACME")
      # @param mobile_trigger_id [String] Mobile trigger checkbox ID
      def initialize(current_path:, fixed: true, collapsible: false, collapsable: nil,
                     group_behavior: :expandable,
                     brand: nil, mobile_trigger_id: MOBILE_TRIGGER_ID, **options)
        @current_path = current_path
        @fixed = fixed
        @collapsible = collapsable.nil? ? collapsible : collapsable
        @group_behavior = GROUP_BEHAVIORS.include?(group_behavior) ? group_behavior : :expandable
        @brand = brand
        @mobile_trigger_id = mobile_trigger_id
        @options = options
      end

      def fixed?
        @fixed
      end

      def collapsible?
        @collapsible
      end

      alias collapsable? collapsible?

      def expandable_groups?
        @group_behavior == :expandable
      end

      def dropdown_groups?
        @group_behavior == :dropdown
      end

      # Unique ID for the collapse checkbox (needed for CSS selectors)
      def collapse_checkbox_id
        @collapse_checkbox_id ||= "side-menu-collapse-#{object_id}"
      end

      def container_classes
        class_names(
          "side-menu-component",
          { "side-menu-component--fixed" => @fixed },
          { "side-menu-component--inline" => !@fixed },
          @options[:class]
        )
      end

      def container_data
        data = @options[:data] || {}
        data[:controller] =
          class_names(data[:controller], { "side-menu" => @collapsible || @fixed })
        data[:side_menu_collapse_checkbox_value] = collapse_checkbox_id if @collapsible
        data[:side_menu_mobile_trigger_value] = @mobile_trigger_id if @fixed
        data
      end

      def container_options
        opts = @options.except(:class, :data)
        opts[:class] = container_classes
        opts[:data] = container_data
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
        authorized_menus.find(&:active?)
      end

      attr_reader :brand, :mobile_trigger_id

      def brand?
        @brand.present?
      end

      # Translated aria-label for mobile trigger checkbox
      def toggle_mobile_label
        I18n.t("bali.side_menu.toggle_mobile", default: "Toggle sidebar")
      end

      # Translated aria-label for collapse checkbox
      def toggle_collapse_label
        I18n.t("bali.side_menu.toggle_collapse", default: "Toggle sidebar collapse")
      end

      # Translated title for collapse button
      def collapse_label
        I18n.t("bali.side_menu.collapse", default: "Collapse sidebar")
      end

      # Translated title for expand button
      def expand_label
        I18n.t("bali.side_menu.expand", default: "Expand sidebar")
      end
    end
  end
end
