# frozen_string_literal: true

module Bali
  module Navbar
    class Component < ApplicationViewComponent
      attr_reader :transparency, :fullscreen, :options

      renders_one :brand
      renders_many :burgers, Burger::Component
      renders_many :menus, Menu::Component

      def initialize(transparency: false, fullscreen: false, **options)
        @transparency = transparency.present?
        @fullscreen = fullscreen.present?
        @container_class = options.delete(:container_class)

        @options = prepend_controller(options, 'navbar')
        @options = prepend_class_name(options, 'navbar-component navbar')
        @options = prepend_data_attribute(options, 'navbar-allow-transparency-value', @transparency)
        @options = prepend_data_attribute(options, 'navbar-throttle-interval-value', 100)
      end
    end
  end
end
