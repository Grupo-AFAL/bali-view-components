# frozen_string_literal: true

module Bali
  module PropertiesTable
    class Component < ApplicationViewComponent
      # Clean DaisyUI table with zebra striping - no heavy borders
      BASE_CLASSES = 'table table-zebra properties-table-component'

      renders_many :properties, Bali::PropertiesTable::Property::Component

      def initialize(**options)
        @options = options
      end

      private

      attr_reader :options

      def table_classes
        class_names(BASE_CLASSES, options[:class])
      end

      def table_attributes
        options.except(:class).merge(class: table_classes)
      end
    end
  end
end
