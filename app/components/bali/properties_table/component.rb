# frozen_string_literal: true

module Bali
  module PropertiesTable
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'table properties-table-component'
      BORDER_CLASSES = '[&_td]:border [&_th]:border'
      LAYOUT_CLASSES = '[&_tbody]:inline-table [&_tbody]:w-full'
      LAST_ROW_CLASSES = '[&_tbody_tr:last-child_td]:border-b [&_tbody_tr:last-child_th]:border-b'

      renders_many :properties, Bali::PropertiesTable::Property::Component

      def initialize(**options)
        @options = options
      end

      private

      attr_reader :options

      def table_classes
        class_names(
          BASE_CLASSES,
          BORDER_CLASSES,
          LAYOUT_CLASSES,
          LAST_ROW_CLASSES,
          options[:class]
        )
      end

      def table_attributes
        options.except(:class).merge(class: table_classes)
      end
    end
  end
end
