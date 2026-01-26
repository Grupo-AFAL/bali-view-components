# frozen_string_literal: true

module Bali
  module Clipboard
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'clipboard-component inline-flex items-stretch max-w-full'

      renders_one :trigger, Trigger::Component
      renders_one :source, Source::Component
      renders_one :success_content, SucessContent::Component

      def initialize(**options)
        @options = options
      end

      private

      attr_reader :options

      def component_attributes
        opts = prepend_class_name(options, BASE_CLASSES)
        prepend_controller(opts, 'clipboard')
      end
    end
  end
end
