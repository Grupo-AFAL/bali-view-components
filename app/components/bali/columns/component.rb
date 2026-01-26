# frozen_string_literal: true

module Bali
  module Columns
    class Component < ApplicationViewComponent
      GAPS = {
        none: 'gap-0',
        xs: 'gap-1',
        sm: 'gap-2',
        md: 'gap-4',
        lg: 'gap-6',
        xl: 'gap-8'
      }.freeze

      renders_many :columns, Column::Component

      def initialize(gap: :md, **options)
        @gap = gap&.to_sym
        @options = options
      end

      private

      attr_reader :options

      def container_classes
        class_names(
          'flex flex-wrap',
          GAPS[@gap] || GAPS[:md],
          options[:class]
        )
      end
    end
  end
end
