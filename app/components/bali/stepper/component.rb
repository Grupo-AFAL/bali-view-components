# frozen_string_literal: true

module Bali
  module Stepper
    class Component < ApplicationViewComponent
      attr_reader :current, :options

      renders_many :steps, ->(title:, **options, &block) do
        @index += 1
        Step::Component.new(title: title, current: @current, index: @index, **options, &block)
      end

      def initialize(current: 0, **options)
        @index = -1
        @current = current
        @options = prepend_class_name(options, 'stepper-component')
      end
    end
  end
end
