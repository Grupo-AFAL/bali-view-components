# frozen_string_literal: true

module Bali
  module Navbar
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'navbar shadow-sm'
      STICKY_CLASSES = 'sticky top-0 z-50'

      COLORS = {
        base: 'bg-base-100',
        primary: 'bg-primary text-primary-content',
        secondary: 'bg-secondary text-secondary-content',
        accent: 'bg-accent text-accent-content',
        neutral: 'bg-neutral text-neutral-content'
      }.freeze

      # Brand slot - accepts content block or name parameter
      renders_one :brand

      renders_many :burgers, Burger::Component
      renders_many :menus, Menu::Component

      # @param sticky [Boolean] Make navbar sticky at top (default: true)
      # @param transparency [Boolean] Enable transparent mode
      # @param fullscreen [Boolean] Full-width navbar without max-width constraint
      # @param color [Symbol] Background color (:base, :primary, :secondary, :accent, :neutral)
      def initialize(sticky: true, transparency: false, fullscreen: false, color: :base, **options)
        @sticky = sticky
        @transparency = transparency.present?
        @fullscreen = fullscreen.present?
        @color = color&.to_sym
        @container_class = options.delete(:container_class)

        @options = prepend_controller(options, 'navbar')
        @options = prepend_class_name(options, navbar_classes)
        @options = prepend_data_attribute(options, 'navbar-allow-transparency-value', @transparency)
        @options = prepend_data_attribute(options, 'navbar-throttle-interval-value', 100)
      end

      # Classes for the inner container wrapper
      # - Fullscreen: edge-to-edge with padding, no width constraint
      # - Non-fullscreen: centered with max-width constraint (max-w-7xl = 1280px)
      def container_classes
        base = 'flex items-center w-full relative px-4'
        if @fullscreen
          class_names(base, @container_class)
        else
          class_names(base, 'max-w-7xl mx-auto', @container_class)
        end
      end

      private

      attr_reader :transparency, :fullscreen, :sticky, :options

      def navbar_classes
        class_names(
          BASE_CLASSES,
          COLORS.fetch(@color, COLORS[:base]),
          @sticky && STICKY_CLASSES,
          @options[:class]
        )
      end
    end
  end
end
