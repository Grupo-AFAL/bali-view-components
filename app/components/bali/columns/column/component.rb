# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        attr_reader :options

        # Flexbox-based column widths
        # Note: We use calc() to account for gap spacing in flex layouts
        SIZES = {
          half: 'w-[calc(50%-0.5rem)]',
          third: 'w-[calc(33.333%-0.67rem)]',
          two_thirds: 'w-[calc(66.666%-0.33rem)]',
          quarter: 'w-[calc(25%-0.75rem)]',
          three_quarters: 'w-[calc(75%-0.25rem)]',
          narrow: 'w-auto flex-none',
          full: 'w-full'
        }.freeze

        # Offsets use margin-left for flexbox
        OFFSETS = {
          quarter: 'ml-[25%]',
          third: 'ml-[33.333%]',
          half: 'ml-[50%]'
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
          SIZES[@size] || 'flex-1'
        end
      end
    end
  end
end
