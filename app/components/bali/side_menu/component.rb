# frozen_string_literal: true

module Bali
  module SideMenu
    class Component < ApplicationViewComponent
      renders_many :lists, List::Component

      def initialize(**options)
        @options = options
        @options = prepend_class_name(@options, 'side-menu-component')
        @options = prepend_data_attribute(@options, :side_menu_target, 'container')
      end
    end
  end
end
