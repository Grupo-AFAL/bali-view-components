# frozen_string_literal: true

module Bali
  module SideMenu
    class Component < ApplicationViewComponent
      # Group behavior modes for nested menu items
      # - :expandable - Click to expand/collapse using DaisyUI collapse (default)
      # - :dropdown - Show submenu in dropdown on hover
      GROUP_BEHAVIORS = %i[expandable dropdown].freeze

      renders_many :menu_switches, Bali::SideMenu::MenuSwitch::Component

      renders_many :lists, ->(title: nil, **options) do
        List::Component.new(
          title: title,
          current_path: @current_path,
          group_behavior: @group_behavior,
          **options
        )
      end

      # @param current_path [String] The current request path for active state detection
      # @param fixed [Boolean] Fixed to viewport (true) or inline flow (false). Default: true
      # @param collapsable [Boolean] Whether the sidebar can collapse to icon-only mode
      # @param group_behavior [Symbol] How nested items behave - :expandable (click) or :dropdown (hover)
      def initialize(current_path:, fixed: true, collapsable: false, group_behavior: :expandable, **options)
        @current_path = current_path
        @fixed = fixed
        @collapsable = collapsable
        @group_behavior = GROUP_BEHAVIORS.include?(group_behavior) ? group_behavior : :expandable
        @options = options
      end

      def fixed?
        @fixed
      end

      def collapsable?
        @collapsable
      end

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
          'side-menu-component',
          { 'side-menu-component--fixed' => @fixed },
          @options[:class]
        )
      end

      def container_data
        data = @options[:data] || {}
        data[:controller] = class_names(data[:controller], { 'side-menu' => @collapsable || @fixed })
        data[:side_menu_collapse_checkbox_value] = collapse_checkbox_id if @collapsable
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
    end
  end
end
