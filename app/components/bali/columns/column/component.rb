# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        # Flexbox-based column sizes using basis and grow utilities
        SIZES = {
          full: 'basis-full',
          half: 'basis-1/2',
          third: 'basis-1/3',
          two_thirds: 'basis-2/3',
          quarter: 'basis-1/4',
          three_quarters: 'basis-3/4',
          auto: 'shrink-0' # Don't shrink, just fit content
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
            grow_class,
            'min-w-0',
            @options[:class]
          )
        end

        def size_class
          SIZES[@size] || SIZES[:full]
        end

        # All columns grow except :auto which shrinks to fit content
        def grow_class
          @size == :auto ? nil : 'grow'
        end
      end
    end
  end
end
