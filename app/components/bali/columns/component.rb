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

      # Explicit class names so Tailwind's scanner can detect them
      GRID_COLS = {
        1 => "grid-cols-1", 2 => "grid-cols-2", 3 => "grid-cols-3",
        4 => "grid-cols-4", 5 => "grid-cols-5", 6 => "grid-cols-6",
        7 => "grid-cols-7", 8 => "grid-cols-8", 9 => "grid-cols-9",
        10 => "grid-cols-10", 11 => "grid-cols-11", 12 => "grid-cols-12"
      }.freeze

      RESPONSIVE_GRID_COLS = {
        md: {
          1 => "md:grid-cols-1", 2 => "md:grid-cols-2", 3 => "md:grid-cols-3",
          4 => "md:grid-cols-4", 5 => "md:grid-cols-5", 6 => "md:grid-cols-6",
          7 => "md:grid-cols-7", 8 => "md:grid-cols-8", 9 => "md:grid-cols-9",
          10 => "md:grid-cols-10", 11 => "md:grid-cols-11", 12 => "md:grid-cols-12"
        }.freeze,
        lg: {
          1 => "lg:grid-cols-1", 2 => "lg:grid-cols-2", 3 => "lg:grid-cols-3",
          4 => "lg:grid-cols-4", 5 => "lg:grid-cols-5", 6 => "lg:grid-cols-6",
          7 => "lg:grid-cols-7", 8 => "lg:grid-cols-8", 9 => "lg:grid-cols-9",
          10 => "lg:grid-cols-10", 11 => "lg:grid-cols-11", 12 => "lg:grid-cols-12"
        }.freeze,
        xl: {
          1 => "xl:grid-cols-1", 2 => "xl:grid-cols-2", 3 => "xl:grid-cols-3",
          4 => "xl:grid-cols-4", 5 => "xl:grid-cols-5", 6 => "xl:grid-cols-6",
          7 => "xl:grid-cols-7", 8 => "xl:grid-cols-8", 9 => "xl:grid-cols-9",
          10 => "xl:grid-cols-10", 11 => "xl:grid-cols-11", 12 => "xl:grid-cols-12"
        }.freeze
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

      private

      def grid_mode?
        @cols.present? && !columns?
      end

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
          GAPS.fetch(@gap),
          { "flex-wrap" => @wrap },
          { "justify-center" => @center },
          { "items-center" => @middle },
          options[:class]
        )
      end

      def grid_classes
        class_names(
          "grid",
          GAPS.fetch(@gap),
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
