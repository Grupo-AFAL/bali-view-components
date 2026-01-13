# frozen_string_literal: true

module Bali
  module List
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, Item::Component

      def initialize(borderless: false, relaxed_spacing: false, **options)
        @borderless = borderless
        @relaxed_spacing = relaxed_spacing
        @options = prepend_class_name(options, list_classes)
      end

      private

      def list_classes
        class_names(
          'list-component',
          'border border-base-300' => !@borderless,
          '[&_.list-item-component]:py-4' => @relaxed_spacing
        )
      end
    end
  end
end
