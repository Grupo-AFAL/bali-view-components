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
      # @param multiline [Boolean] Allow columns to wrap to multiple lines (Bulma: is-multiline)
      # @param centered [Boolean] Center columns horizontally (Bulma: is-centered)
      # @param vcentered [Boolean] Center columns vertically (Bulma: is-vcentered)
      # @param mobile [Boolean] Keep columns on mobile instead of stacking (Bulma: is-mobile)
      def initialize(gap: :md, multiline: false, centered: false,
                     vcentered: false, mobile: false, **options)
        @gap = gap&.to_sym
        @multiline = multiline
        @centered = centered
        @vcentered = vcentered
        @mobile = mobile
        @options = options
      end

      private

      attr_reader :options

      def container_classes
        class_names(
          'columns',
          GAPS[@gap] || GAPS[:md],
          { 'is-multiline' => @multiline },
          { 'is-centered' => @centered },
          { 'is-vcentered' => @vcentered },
          { 'is-mobile' => @mobile },
          options[:class]
        )
      end
    end
  end
end
