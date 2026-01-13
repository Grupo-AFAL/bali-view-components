# frozen_string_literal: true

module Bali
  module Clipboard
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :trigger, Trigger::Component
      renders_one :source, Source::Component
      renders_one :success_content, SucessContent::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'clipboard-component flex')
        @options = prepend_controller(@options, 'clipboard')
      end
    end
  end
end
