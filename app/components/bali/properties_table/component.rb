# frozen_string_literal: true

module Bali
  module PropertiesTable
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :properties, Bali::PropertiesTable::Property::Component

      TABLE_CLASSES = [
        'table properties-table-component',
        '[&_td]:border [&_th]:border',
        '[&_tbody]:inline-table [&_tbody]:w-full',
        '[&_tbody_tr:last-child_td]:border-b [&_tbody_tr:last-child_th]:border-b'
      ].join(' ').freeze

      def initialize(**options)
        @options = prepend_class_name(options, TABLE_CLASSES)
      end
    end
  end
end
