# frozen_string_literal: true

module Bali
  module Reveal
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'reveal-component select-none group'
      OPENED_CLASS = 'is-revealed'

      renders_one :trigger, Reveal::Trigger::Component

      def initialize(opened: false, **options)
        @opened = opened
        @options = options
      end

      private

      attr_reader :opened, :options

      def component_classes
        class_names(
          BASE_CLASSES,
          { OPENED_CLASS => opened },
          options[:class]
        )
      end

      def component_options
        options
          .except(:class)
          .merge(class: component_classes)
          .tap { |opts| prepend_controller(opts, 'reveal') }
      end

      def content_classes
        'reveal-content mb-8 hidden group-[.is-revealed]:block'
      end
    end
  end
end
