# frozen_string_literal: true

module Bali
  module Navbar
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'navbar shadow-sm'

      COLORS = {
        base: 'bg-base-100',
        primary: 'bg-primary text-primary-content',
        secondary: 'bg-secondary text-secondary-content',
        accent: 'bg-accent text-accent-content',
        neutral: 'bg-neutral text-neutral-content'
      }.freeze

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

      def navbar_content
        render_string = []
        render_string << tag.div(class: 'navbar-start') do
          safe_join([
                      brand,
                      burgers? ? safe_join(burgers) : render(Bali::Navbar::Burger::Component.new)
                    ])
        end
        menus.each { |menu| render_string << menu }
        safe_join(render_string)
      end

      private

      attr_reader :transparency, :fullscreen, :options

      def navbar_classes
        class_names(
          BASE_CLASSES,
          COLORS.fetch(@color, COLORS[:base]),
          @options[:class]
        )
      end
    end
  end
end
