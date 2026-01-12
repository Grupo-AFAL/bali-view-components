# frozen_string_literal: true

module Bali
  module Level
    class Component < ApplicationViewComponent
      ALIGNMENTS = {
        start: 'items-start',
        center: 'items-center',
        end: 'items-end'
      }.freeze

      attr_reader :options

      renders_one :left, ->(**args) do
        Side::Component.new(position: :left, **args)
      end
      renders_one :right, ->(**args) do
        Side::Component.new(position: :right, **args)
      end

      renders_many :items, Item::Component

      def initialize(align: :center, **options)
        @align = align&.to_sym
        @options = prepend_class_name(options, level_classes)
      end

      def level_classes
        class_names(
          'level flex justify-between gap-4',
          ALIGNMENTS[@align] || ALIGNMENTS[:center]
        )
      end
    end
  end
end
