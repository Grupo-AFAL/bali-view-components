# frozen_string_literal: true

module Bali
  module PropertiesTable
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :properties, Bali::PropertiesTable::Property::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'table properties-table-component')
      end
    end
  end
end
