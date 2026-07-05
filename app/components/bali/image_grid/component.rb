# frozen_string_literal: true

module Bali
  module ImageGrid
    class Component < ApplicationViewComponent
      COLUMNS = {
        2 => "grid-cols-2",
        3 => "grid-cols-3",
        4 => "grid-cols-4",
        5 => "grid-cols-5",
        6 => "grid-cols-6"
      }.freeze

      GAPS = {
        none: "gap-0",
        sm: "gap-2",
        md: "gap-4",
        lg: "gap-6"
      }.freeze

      renders_many :images, ->(**opts) {
        Image::Component.new(**{ expandable: @expandable }.merge(opts))
      }

      # Rendered instead of the grid when there are no images — typically an
      # "add image" button/link (issue #27).
      renders_one :empty_state

      def initialize(columns: 4, gap: :md, expandable: false, **options)
        @columns = columns
        @gap = gap.to_sym
        @expandable = expandable
        @options = options
      end

      private

      attr_reader :columns, :gap, :options

      def grid_classes
        class_names(
          "grid",
          COLUMNS[columns],
          GAPS[gap],
          options[:class]
        )
      end

      def grid_attributes
        options.except(:class)
      end
    end
  end
end
