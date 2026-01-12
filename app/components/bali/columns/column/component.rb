# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        attr_reader :options

        SIZES = {
          half: 'col-span-6',
          third: 'col-span-4',
          two_thirds: 'col-span-8',
          quarter: 'col-span-3',
          three_quarters: 'col-span-9',
          narrow: 'col-span-2',
          full: 'col-span-12'
        }.freeze

        OFFSETS = {
          quarter: 'col-start-4',
          third: 'col-start-5',
          half: 'col-start-7'
        }.freeze

        def initialize(size: nil, offset: nil, **options)
          @size = size&.to_sym
          @offset = offset&.to_sym
          @options = prepend_class_name(options, column_classes)
        end

        def call
          tag.div(content, **options)
        end

        private

        def column_classes
          class_names(
            'column min-w-0',
            size_class,
            OFFSETS[@offset]
          )
        end

        def size_class
          SIZES[@size] || 'col-span-6'
        end
      end
    end
  end
end
