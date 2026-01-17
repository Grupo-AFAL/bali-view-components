# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        # CSS Grid column spans - gap is handled automatically by parent grid
        SIZES = {
          full: 'col-span-12',
          half: 'col-span-6',
          third: 'col-span-4',
          two_thirds: 'col-span-8',
          quarter: 'col-span-3',
          three_quarters: 'col-span-9',
          auto: 'col-auto'
        }.freeze

        # Grid column start positions for offsets
        OFFSETS = {
          quarter: 'col-start-4',
          third: 'col-start-5',
          half: 'col-start-7'
        }.freeze

        def initialize(size: nil, offset: nil, **options)
          @size = size&.to_sym
          @offset = offset&.to_sym
          @options = options
        end

        def call
          tag.div(content, class: column_classes, **@options.except(:class))
        end

        private

        def column_classes
          class_names(
            size_class,
            OFFSETS[@offset],
            # Prevents content from overflowing grid cell boundaries
            'min-w-0',
            @options[:class]
          )
        end

        def size_class
          SIZES[@size] || SIZES[:full]
        end
      end
    end
  end
end
