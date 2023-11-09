# frozen_string_literal: true

module Bali
  module HelloButton
    class Component < ApplicationViewComponent
      attr_reader :label, :options

      def initialize(label:, **options)
        @label = label
        @options = prepend_class_name(options, 'hello-button-component')
      end
    end
  end
end
