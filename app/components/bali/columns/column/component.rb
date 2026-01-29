# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        # Numeric sizes (Bulma: is-1 through is-12)
        NUMERIC_SIZES = (1..12).index_with { |n| "is-#{n}" }.freeze

        # Fractional sizes (Bulma: is-half, is-one-third, etc.)
        SYMBOLIC_SIZES = {
          full: 'is-full',
          half: 'is-half',
          one_third: 'is-one-third',
          third: 'is-one-third',
          two_thirds: 'is-two-thirds',
          one_quarter: 'is-one-quarter',
          quarter: 'is-one-quarter',
          three_quarters: 'is-three-quarters',
          one_fifth: 'is-one-fifth',
          two_fifths: 'is-two-fifths',
          three_fifths: 'is-three-fifths',
          four_fifths: 'is-four-fifths'
        }.freeze

        # Numeric offsets (Bulma: is-offset-1 through is-offset-11)
        NUMERIC_OFFSETS = (1..11).index_with { |n| "is-offset-#{n}" }.freeze

        # Fractional offsets (Bulma: is-offset-half, is-offset-one-third, etc.)
        SYMBOLIC_OFFSETS = {
          half: 'is-offset-half',
          one_third: 'is-offset-one-third',
          third: 'is-offset-one-third',
          two_thirds: 'is-offset-two-thirds',
          one_quarter: 'is-offset-one-quarter',
          quarter: 'is-offset-one-quarter',
          three_quarters: 'is-offset-three-quarters',
          one_fifth: 'is-offset-one-fifth',
          two_fifths: 'is-offset-two-fifths',
          three_fifths: 'is-offset-three-fifths',
          four_fifths: 'is-offset-four-fifths'
        }.freeze

        # @param size [Symbol, Integer, nil] Column width - symbolic or numeric (1-12)
        # @param offset [Symbol, Integer, nil] Column offset - symbolic or numeric (1-11)
        # @param narrow [Boolean] Make column only as wide as its content (Bulma: is-narrow)
        def initialize(size: nil, offset: nil, narrow: false, **options)
          @size = size
          @offset = offset
          @narrow = narrow
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
            { 'is-narrow' => @narrow },
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
