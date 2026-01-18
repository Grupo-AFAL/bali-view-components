# frozen_string_literal: true

module Bali
  module SideMenu
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'side-menu-component'
      HOVERCARD_Z_INDEX = 38

      renders_many :menu_switches, Bali::SideMenu::MenuSwitch::Component

      renders_many :lists, ->(title: nil, **options) do
        List::Component.new(title: title, current_path: @current_path, **options)
      end

      def initialize(current_path:, collapsable: false, **options)
        @current_path = current_path
        @collapsable = collapsable
        @options = options
      end

      def container_options
        opts = @options.dup
        opts[:class] = class_names(BASE_CLASSES, opts[:class])
        opts[:data] = container_data(opts[:data])
        opts
      end

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

      def show_divider?
        collapsable? || authorized_menus.any?
      end

      def collapsable?
        @collapsable
      end

      private

      def container_data(existing_data = nil)
        base_data = existing_data || {}
        result = base_data.merge(
          side_menu_target: 'container',
          collapsable: @collapsable
        )
        result[:controller] = prepend_controller(result[:controller], 'side-menu') if @collapsable
        result
      end

      def prepend_controller(existing, new_controller)
        return new_controller if existing.blank?
        return existing if existing.to_s.include?(new_controller)

        "#{new_controller} #{existing}"
      end
    end
  end
end
