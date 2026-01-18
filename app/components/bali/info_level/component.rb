# frozen_string_literal: true

module Bali
  module InfoLevel
    class Component < ApplicationViewComponent
      ALIGNMENTS = {
        start: 'justify-start',
        center: 'justify-center',
        end: 'justify-end',
        between: 'justify-between'
      }.freeze

      BASE_CLASSES = 'info-level-component flex flex-wrap gap-8'

      renders_many :items, Item::Component

      def initialize(align: :center, **options)
        @align = align.to_sym
        @options = prepend_class_name(options, info_level_classes)
      end

      private

      attr_reader :options

      def info_level_classes
        class_names(
          BASE_CLASSES,
          ALIGNMENTS.fetch(@align, ALIGNMENTS[:center])
        )
      end
    end
  end
end
