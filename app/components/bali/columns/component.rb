# frozen_string_literal: true

module Bali
  module Columns
    class Component < ApplicationViewComponent
      # Gap sizes using Tailwind-like naming
      GAPS = {
        none: "gap-none",  # 0
        px: "gap-px",      # 1px
        xs: "gap-xs",      # 0.25rem (gap-1)
        sm: "gap-sm",      # 0.5rem (gap-2)
        md: "gap-md",      # 0.75rem (gap-3) - default
        lg: "gap-lg",      # 1rem (gap-4)
        xl: "gap-xl",      # 1.5rem (gap-6)
        '2xl': "gap-2xl"   # 2rem (gap-8)
      }.freeze

      GRID_COLS = (1..12).index_with { |n| "cols-#{n}" }.freeze

      renders_many :columns, Column::Component

      # @param gap [Symbol] Gap size (:none, :px, :xs, :sm, :md, :lg, :xl, :'2xl')
      # @param cols [Integer, nil] Auto-flow grid columns (1-12). Children auto-arrange without with_column wrappers.
      # @param cols_tablet [Integer, nil] Grid columns at tablet breakpoint (769px+)
      # @param cols_desktop [Integer, nil] Grid columns at desktop breakpoint (1024px+)
      # @param cols_widescreen [Integer, nil] Grid columns at widescreen breakpoint (1216px+)
      # @param wrap [Boolean] Allow columns to wrap to multiple lines
      # @param center [Boolean] Center columns horizontally
      # @param middle [Boolean] Center columns vertically
      # @param mobile [Boolean] Keep columns on mobile instead of stacking
      def initialize(gap: :md, cols: nil, cols_tablet: nil, cols_desktop: nil,
                     cols_widescreen: nil, wrap: false, center: false,
                     middle: false, mobile: false, **options)
        @gap = gap&.to_sym
        @cols = cols
        @cols_tablet = cols_tablet
        @cols_desktop = cols_desktop
        @cols_widescreen = cols_widescreen
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
        class_names(
          "columns",
          GAPS[@gap] || GAPS[:md],
          { "columns-wrap" => @wrap },
          { "columns-center" => @center },
          { "columns-middle" => @middle },
          { "columns-mobile" => @mobile },
          options[:class]
        )
      end

      def grid_classes
        class_names(
          "columns-grid",
          GAPS[@gap] || GAPS[:md],
          GRID_COLS[@cols],
          cols_breakpoint_class(@cols_tablet, :tablet),
          cols_breakpoint_class(@cols_desktop, :desktop),
          cols_breakpoint_class(@cols_widescreen, :widescreen),
          options[:class]
        )
      end

      def cols_breakpoint_class(value, breakpoint)
        "cols-#{value}-#{breakpoint}" if value.present?
      end
    end
  end
end
