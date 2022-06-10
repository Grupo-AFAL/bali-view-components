# frozen_string_literal: true

module Bali
  module Navbar
    class Component < ApplicationViewComponent
      attr_reader :transparency, :fullscreen,  :options

      renders_one :brand
      renders_one :burger, Burger::Component
      renders_many :left_items, Item::Component
      renders_many :right_items, Item::Component

      def initialize(transparency: false, fullscreen: false, **options)
        @transparency = transparency
        @fullscreen = fullscreen

        @options = prepend_controller(options, 'navbar')
        @options = prepend_class_name(options, 'navbar-component navbar')
        @options = prepend_data_attribute(options, 'navbar-allow-transparency-value', transparency)
        @options = prepend_data_attribute(options, 'navbar-throttle-interval-value', 100)
      end
    end
  end
end
