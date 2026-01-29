# frozen_string_literal: true

module Bali
  module Columns
    class Component < ApplicationViewComponent
      # Gap sizes using Tailwind-like naming
      GAPS = {
        none: 'gap-none',  # 0
        px: 'gap-px',      # 1px
        xs: 'gap-xs',      # 0.25rem (gap-1)
        sm: 'gap-sm',      # 0.5rem (gap-2)
        md: 'gap-md',      # 0.75rem (gap-3) - default
        lg: 'gap-lg',      # 1rem (gap-4)
        xl: 'gap-xl',      # 1.5rem (gap-6)
        '2xl': 'gap-2xl'   # 2rem (gap-8)
      }.freeze

      renders_many :columns, Column::Component

      # @param gap [Symbol] Gap size (:none, :px, :xs, :sm, :md, :lg, :xl, :'2xl')
      # @param wrap [Boolean] Allow columns to wrap to multiple lines
      # @param center [Boolean] Center columns horizontally
      # @param middle [Boolean] Center columns vertically
      # @param mobile [Boolean] Keep columns on mobile instead of stacking
      def initialize(gap: :md, wrap: false, center: false,
                     middle: false, mobile: false, **options)
        @gap = gap&.to_sym
        @wrap = wrap
        @center = center
        @middle = middle
        @mobile = mobile
        @options = options
      end

      private

      attr_reader :options

      def container_classes
        class_names(
          'columns',
          GAPS[@gap] || GAPS[:md],
          { 'columns-wrap' => @wrap },
          { 'columns-center' => @center },
          { 'columns-middle' => @middle },
          { 'columns-mobile' => @mobile },
          options[:class]
        )
      end
    end
  end
end
