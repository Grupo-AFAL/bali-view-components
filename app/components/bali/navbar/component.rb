# frozen_string_literal: true

module Bali
  module Navbar
    class Component < ApplicationViewComponent
      COLORS = {
        base: 'bg-base-100',
        primary: 'bg-primary text-primary-content',
        secondary: 'bg-secondary text-secondary-content',
        accent: 'bg-accent text-accent-content',
        neutral: 'bg-neutral text-neutral-content'
      }.freeze

      attr_reader :transparency, :fullscreen, :options

      renders_one :brand
      renders_many :burgers, Burger::Component
      renders_many :menus, Menu::Component

      def initialize(transparency: false, fullscreen: false, color: :base, **options)
        @transparency = transparency.present?
        @fullscreen = fullscreen.present?
        @color = color&.to_sym
        @container_class = options.delete(:container_class)

        @options = prepend_controller(options, 'navbar')
        @options = prepend_class_name(options, navbar_classes)
        @options = prepend_data_attribute(options, 'navbar-allow-transparency-value', @transparency)
        @options = prepend_data_attribute(options, 'navbar-throttle-interval-value', 100)
      end

      def navbar_classes
        class_names(
          'navbar',
          COLORS[@color] || COLORS[:base],
          'shadow-sm',
          @options[:class]
        )
      end
    end
  end
end
