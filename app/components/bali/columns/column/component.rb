# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        # Numeric sizes (col-1 through col-12)
        NUMERIC_SIZES = (1..12).index_with { |n| "col-#{n}" }.freeze

        # Fractional sizes
        SYMBOLIC_SIZES = {
          full: 'col-full',
          half: 'col-half',
          one_third: 'col-third',
          third: 'col-third',
          two_thirds: 'col-2-thirds',
          one_quarter: 'col-quarter',
          quarter: 'col-quarter',
          three_quarters: 'col-3-quarters',
          one_fifth: 'col-fifth',
          two_fifths: 'col-2-fifths',
          three_fifths: 'col-3-fifths',
          four_fifths: 'col-4-fifths'
        }.freeze

        # Numeric offsets (offset-1 through offset-11)
        NUMERIC_OFFSETS = (1..11).index_with { |n| "offset-#{n}" }.freeze

        # Fractional offsets
        SYMBOLIC_OFFSETS = {
          half: 'offset-half',
          one_third: 'offset-third',
          third: 'offset-third',
          two_thirds: 'offset-2-thirds',
          one_quarter: 'offset-quarter',
          quarter: 'offset-quarter',
          three_quarters: 'offset-3-quarters',
          one_fifth: 'offset-fifth',
          two_fifths: 'offset-2-fifths',
          three_fifths: 'offset-3-fifths',
          four_fifths: 'offset-4-fifths'
        }.freeze

        # @param size [Symbol, Integer, nil] Column width - symbolic or numeric (1-12)
        # @param offset [Symbol, Integer, nil] Column offset - symbolic or numeric (1-11)
        # @param auto [Boolean] Make column only as wide as its content
        def initialize(size: nil, offset: nil, auto: false, **options)
          @size = size
          @offset = offset
          @auto = auto
          @options = options
        end

        def call
          tag.div(content, class: column_classes, **@options.except(:class))
        end

        private

        def column_classes
          class_names(
            'column',
            size_class,
            offset_class,
            { 'col-auto' => @auto },
            @options[:class]
          )
        end

        def size_class
          case @size
          when Integer
            NUMERIC_SIZES[@size]
          when Symbol
            SYMBOLIC_SIZES[@size]
          end
        end

        def offset_class
          case @offset
          when Integer
            NUMERIC_OFFSETS[@offset]
          when Symbol
            SYMBOLIC_OFFSETS[@offset]
          end
        end
      end
    end
  end
end
