# frozen_string_literal: true

module Bali
  module PropertiesTable
    module Property
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'properties-table-property-component'
        # Use th for label cell - semantically correct for row headers
        # font-medium for subtle emphasis, text-base-content/70 for hierarchy
        LABEL_CLASSES = 'property-label font-medium text-base-content/70 w-1/3'
        VALUE_CLASSES = 'property-value'

        def initialize(label:, value: nil, **options)
          @label = label
          @value = value
          @options = options
        end

        private

        attr_reader :label, :value, :options

        def row_classes
          class_names(BASE_CLASSES, options[:class])
        end

        def row_attributes
          options.except(:class).merge(class: row_classes)
        end
      end
    end
  end
end
