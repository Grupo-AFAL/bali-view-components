# frozen_string_literal: true

module Bali
  module Level
    class Component < ApplicationViewComponent
      ALIGNMENTS = {
        start: 'items-start',
        center: 'items-center',
        end: 'items-end'
      }.freeze

      BASE_CLASSES = 'level flex justify-between gap-4'

      renders_one :left, ->(**args) { Side::Component.new(position: :left, **args) }
      renders_one :right, ->(**args) { Side::Component.new(position: :right, **args) }
      renders_many :items, Item::Component

      def initialize(align: :center, **options)
        @align = align.to_sym
        @options = options
      end

      private

      attr_reader :options

      def level_classes
        class_names(
          BASE_CLASSES,
          ALIGNMENTS.fetch(@align, ALIGNMENTS[:center]),
          options[:class]
        )
      end
    end
  end
end
