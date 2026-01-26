# frozen_string_literal: true

module Bali
  module Stepper
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'steps'

      ORIENTATIONS = {
        horizontal: 'steps-horizontal',
        vertical: 'steps-vertical'
      }.freeze

      renders_many :steps, ->(title:, **options) do
        @index += 1
        Step::Component.new(
          title: title,
          current: current,
          index: @index,
          color: color,
          **options
        )
      end

      attr_reader :current, :orientation, :color

      def initialize(current: 0, orientation: :horizontal, color: :primary, **options)
        @index = -1
        @current = current
        @orientation = orientation
        @color = color
        @options = options
      end

      private

      attr_reader :options

      def component_classes
        class_names(
          BASE_CLASSES,
          ORIENTATIONS.fetch(orientation, ORIENTATIONS[:horizontal]),
          options[:class]
        )
      end

      def component_options
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
