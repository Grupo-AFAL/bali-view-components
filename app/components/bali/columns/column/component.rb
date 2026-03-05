# frozen_string_literal: true

module Bali
  module Columns
    module Column
      class Component < ApplicationViewComponent
        # Numeric sizes map to Tailwind width fractions
        NUMERIC_WIDTHS = {
          1 => "w-1/12", 2 => "w-2/12", 3 => "w-3/12", 4 => "w-4/12",
          5 => "w-5/12", 6 => "w-6/12", 7 => "w-7/12", 8 => "w-8/12",
          9 => "w-9/12", 10 => "w-10/12", 11 => "w-11/12", 12 => "w-full"
        }.freeze

        # Fractional sizes
        SYMBOLIC_WIDTHS = {
          full: "w-full",
          half: "w-1/2",
          one_third: "w-1/3",
          third: "w-1/3",
          two_thirds: "w-2/3",
          one_quarter: "w-1/4",
          quarter: "w-1/4",
          three_quarters: "w-3/4",
          one_fifth: "w-1/5",
          two_fifths: "w-2/5",
          three_fifths: "w-3/5",
          four_fifths: "w-4/5"
        }.freeze

        # @param size [Symbol, Integer, nil] Column width - symbolic or numeric (1-12)
        # @param md [Symbol, Integer, nil] Column width at md breakpoint (768px+)
        # @param lg [Symbol, Integer, nil] Column width at lg breakpoint (1024px+)
        # @param xl [Symbol, Integer, nil] Column width at xl breakpoint (1280px+)
        # @param auto [Boolean] Make column only as wide as its content
        # @param stacking [Boolean] Internal: whether parent stacks on mobile (adds md: prefix)
        def initialize(size: nil, md: nil, lg: nil, xl: nil,
                       auto: false, stacking: false, **options)
          @size = size
          @md = md
          @lg = lg
          @xl = xl
          @auto = auto
          @stacking = stacking
          @options = options
        end

        def call
          tag.div(content, class: column_classes, **@options.except(:class))
        end

        private

        def sized?
          @size.present? || @md.present? || @lg.present? || @xl.present?
        end

        def column_classes
          prefix = @stacking ? "md:" : ""

          if @auto
            class_names("#{prefix}w-auto shrink-0", @options[:class])
          elsif sized?
            class_names(
              "min-w-0",
              resolve_width(@size, prefix),
              resolve_width(@md, "md:"),
              resolve_width(@lg, "lg:"),
              resolve_width(@xl, "xl:"),
              @options[:class]
            )
          else
            class_names("#{prefix}flex-1 min-w-0", @options[:class])
          end
        end

        def resolve_width(value, prefix = "")
          case value
          when Integer
            base = NUMERIC_WIDTHS[value]
            "#{prefix}#{base}" if base
          when Symbol
            base = SYMBOLIC_WIDTHS[value]
            "#{prefix}#{base}" if base
          end
        end
      end
    end
  end
end
