# frozen_string_literal: true

module Bali
  module SideMenu
    class Component < ApplicationViewComponent
      renders_many :menu_switches, Bali::SideMenu::MenuSwitch::Component

      renders_many :lists, ->(title: nil, **options) do
        List::Component.new(title: title, current_path: @current_path, **options)
      end

      def initialize(current_path:, collapsable: false, **options)
        @current_path = current_path
        @collapsable = collapsable
        @options = options
        @options = prepend_class_name(@options, 'side-menu-component')
        @options = prepend_data_attribute(@options, :side_menu_target, 'container')
        @options = prepend_data_attribute(@options, :collapsable, @collapsable)
      end
    end
  end
end
