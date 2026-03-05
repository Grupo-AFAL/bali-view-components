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

        # Responsive width classes — explicit for Tailwind scanner detection.
        # Tailwind can't detect classes built via "#{prefix}#{base}" interpolation.
        RESPONSIVE_WIDTHS = {
          "md:" => {
            1 => "md:w-1/12", 2 => "md:w-2/12", 3 => "md:w-3/12", 4 => "md:w-4/12",
            5 => "md:w-5/12", 6 => "md:w-6/12", 7 => "md:w-7/12", 8 => "md:w-8/12",
            9 => "md:w-9/12", 10 => "md:w-10/12", 11 => "md:w-11/12", 12 => "md:w-full",
            full: "md:w-full", half: "md:w-1/2", one_third: "md:w-1/3", third: "md:w-1/3",
            two_thirds: "md:w-2/3", one_quarter: "md:w-1/4", quarter: "md:w-1/4",
            three_quarters: "md:w-3/4", one_fifth: "md:w-1/5", two_fifths: "md:w-2/5",
            three_fifths: "md:w-3/5", four_fifths: "md:w-4/5"
          }.freeze,
          "lg:" => {
            1 => "lg:w-1/12", 2 => "lg:w-2/12", 3 => "lg:w-3/12", 4 => "lg:w-4/12",
            5 => "lg:w-5/12", 6 => "lg:w-6/12", 7 => "lg:w-7/12", 8 => "lg:w-8/12",
            9 => "lg:w-9/12", 10 => "lg:w-10/12", 11 => "lg:w-11/12", 12 => "lg:w-full",
            full: "lg:w-full", half: "lg:w-1/2", one_third: "lg:w-1/3", third: "lg:w-1/3",
            two_thirds: "lg:w-2/3", one_quarter: "lg:w-1/4", quarter: "lg:w-1/4",
            three_quarters: "lg:w-3/4", one_fifth: "lg:w-1/5", two_fifths: "lg:w-2/5",
            three_fifths: "lg:w-3/5", four_fifths: "lg:w-4/5"
          }.freeze,
          "xl:" => {
            1 => "xl:w-1/12", 2 => "xl:w-2/12", 3 => "xl:w-3/12", 4 => "xl:w-4/12",
            5 => "xl:w-5/12", 6 => "xl:w-6/12", 7 => "xl:w-7/12", 8 => "xl:w-8/12",
            9 => "xl:w-9/12", 10 => "xl:w-10/12", 11 => "xl:w-11/12", 12 => "xl:w-full",
            full: "xl:w-full", half: "xl:w-1/2", one_third: "xl:w-1/3", third: "xl:w-1/3",
            two_thirds: "xl:w-2/3", one_quarter: "xl:w-1/4", quarter: "xl:w-1/4",
            three_quarters: "xl:w-3/4", one_fifth: "xl:w-1/5", two_fifths: "xl:w-2/5",
            three_fifths: "xl:w-3/5", four_fifths: "xl:w-4/5"
          }.freeze
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
          if @auto
            class_names(@stacking ? "md:w-auto shrink-0" : "w-auto shrink-0", @options[:class])
          elsif sized?
            class_names(
              "min-w-0",
              resolve_width(@size, @stacking ? "md:" : ""),
              resolve_width(@md, "md:"),
              resolve_width(@lg, "lg:"),
              resolve_width(@xl, "xl:"),
              @options[:class]
            )
          else
            class_names(@stacking ? "md:flex-1 min-w-0" : "flex-1 min-w-0", @options[:class])
          end
        end

        def resolve_width(value, prefix = "")
          return if value.nil?

          if prefix.empty?
            case value
            when Integer then NUMERIC_WIDTHS[value]
            when Symbol then SYMBOLIC_WIDTHS[value]
            end
          else
            RESPONSIVE_WIDTHS.fetch(prefix, {})[value]
          end
        end
      end
    end
  end
end
