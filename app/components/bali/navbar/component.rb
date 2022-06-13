# frozen_string_literal: true

module Bali
  module Navbar
    class Component < ApplicationViewComponent
      attr_reader :transparency, :fullscreen, :split_menu_on_mobile, :options

      renders_one :brand
      renders_many :burgers, Burger::Component
      renders_many :start_items, Item::Component
      renders_many :end_items, Item::Component

      def initialize(transparency: false, fullscreen: false, split_menu_on_mobile: false, **options)
        @transparency = transparency
        @fullscreen = fullscreen
        @split_menu_on_mobile = split_menu_on_mobile

        @options = prepend_controller(options, 'navbar')
        @options = prepend_class_name(options, 'navbar-component navbar')
        @options = prepend_data_attribute(options, 'navbar-allow-transparency-value', transparency)
        @options = prepend_data_attribute(options, 'navbar-throttle-interval-value', 100)
      end
    end
  end
end
