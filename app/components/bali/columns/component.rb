# frozen_string_literal: true

module Bali
  module Columns
    class Component < ApplicationViewComponent
      # Gap sizes using Tailwind utility classes
      GAPS = {
        none: "gap-0",
        px: "gap-px",
        xs: "gap-1",
        sm: "gap-2",
        md: "gap-3",    # default
        lg: "gap-4",
        xl: "gap-6",
        '2xl': "gap-8"
      }.freeze

      GRID_COLS = (1..12).index_with { |n| "grid-cols-#{n}" }.freeze

      # Responsive grid column classes, prebuilt for Tailwind JIT detection
      RESPONSIVE_GRID_COLS = {
        md: (1..12).index_with { |n| "md:grid-cols-#{n}" }.freeze,
        lg: (1..12).index_with { |n| "lg:grid-cols-#{n}" }.freeze,
        xl: (1..12).index_with { |n| "xl:grid-cols-#{n}" }.freeze
      }.freeze

      renders_many :columns, ->(**kwargs) {
        Column::Component.new(stacking: !@mobile, **kwargs)
      }

      # @param gap [Symbol] Gap size (:none, :px, :xs, :sm, :md, :lg, :xl, :'2xl')
      # @param cols [Integer, nil] Auto-flow grid columns (1-12). Children auto-arrange without with_column wrappers.
      # @param cols_md [Integer, nil] Grid columns at md breakpoint (768px+)
      # @param cols_lg [Integer, nil] Grid columns at lg breakpoint (1024px+)
      # @param cols_xl [Integer, nil] Grid columns at xl breakpoint (1280px+)
      # @param wrap [Boolean] Allow columns to wrap to multiple lines
      # @param center [Boolean] Center columns horizontally
      # @param middle [Boolean] Center columns vertically
      # @param mobile [Boolean] Keep columns horizontal on mobile instead of stacking
      def initialize(gap: :md, cols: nil, cols_md: nil, cols_lg: nil,
                     cols_xl: nil, wrap: false, center: false,
                     middle: false, mobile: false, **options)
        @gap = gap&.to_sym
        @cols = cols
        @cols_md = cols_md
        @cols_lg = cols_lg
        @cols_xl = cols_xl
        @wrap = wrap
        @center = center
        @middle = middle
        @mobile = mobile
        @options = options
      end

      def grid_mode?
        @cols.present? && !columns?
      end

      private

      attr_reader :options

      def container_classes
        if grid_mode?
          grid_classes
        else
          flex_classes
        end
      end

      def flex_classes
        base = @mobile ? "flex" : "flex flex-col md:flex-row"

        class_names(
          base,
          GAPS[@gap] || GAPS[:md],
          { "flex-wrap" => @wrap },
          { "justify-center" => @center },
          { "items-center" => @middle },
          options[:class]
        )
      end

      def grid_classes
        class_names(
          "grid",
          GAPS[@gap] || GAPS[:md],
          GRID_COLS[@cols],
          (RESPONSIVE_GRID_COLS[:md][@cols_md] if @cols_md),
          (RESPONSIVE_GRID_COLS[:lg][@cols_lg] if @cols_lg),
          (RESPONSIVE_GRID_COLS[:xl][@cols_xl] if @cols_xl),
          options[:class]
        )
      end
    end
  end
end
