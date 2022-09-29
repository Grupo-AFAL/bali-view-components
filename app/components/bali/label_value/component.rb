# frozen_string_literal: true

module Bali
  module LabelValue
    class Component < ApplicationViewComponent
      attr_reader :label, :value, :options

      def initialize(label:, value: nil, **options)
        @label = label
        @value = value
        @options = prepend_class_name(options, 'label-value-component mb-2')
      end
    end
  end
end
