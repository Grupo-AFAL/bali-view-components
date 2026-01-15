# frozen_string_literal: true

module Bali
  module PropertiesTable
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :properties, Bali::PropertiesTable::Property::Component

      def initialize(**options)
        @options = prepend_class_name(options,
                                      'table properties-table-component [&_td]:border [&_th]:border [&_tbody]:inline-table [&_tbody]:w-full [&_tbody_tr:last-child_td]:border-b [&_tbody_tr:last-child_th]:border-b')
      end
    end
  end
end
