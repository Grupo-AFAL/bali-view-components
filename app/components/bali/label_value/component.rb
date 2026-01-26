# frozen_string_literal: true

module Bali
  module LabelValue
    class Component < ApplicationViewComponent
      LABEL_CLASSES = 'font-bold text-xs text-base-content/70'
      VALUE_CLASSES = 'min-h-6'

      attr_reader :label, :value

      def initialize(label:, value: nil, **options)
        @label = label
        @value = value
        @options = options
      end

      private

      attr_reader :options

      def component_classes
        class_names('mb-2', options[:class])
      end

      def component_attributes
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
