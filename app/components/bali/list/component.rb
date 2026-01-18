# frozen_string_literal: true

module Bali
  module List
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'list'
      BORDERED_CLASSES = 'border border-base-300 rounded-box'

      renders_many :items, Item::Component

      def initialize(borderless: false, relaxed_spacing: false, **options)
        @borderless = borderless
        @relaxed_spacing = relaxed_spacing
        @options = options
      end

      private

      attr_reader :options

      def list_classes
        class_names(
          BASE_CLASSES,
          BORDERED_CLASSES => !@borderless,
          '[&_.list-row]:py-4' => @relaxed_spacing
        )
      end

      def component_options
        prepend_class_name(options, list_classes)
      end
    end
  end
end
