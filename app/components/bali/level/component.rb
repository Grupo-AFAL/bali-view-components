# frozen_string_literal: true

module Bali
  module Level
    class Component < ApplicationViewComponent
      ALIGNMENTS = {
        start: "items-start",
        center: "items-center",
        end: "items-end"
      }.freeze

      BASE_CLASSES = "level flex justify-between max-sm:flex-wrap gap-2 sm:gap-4"

      renders_one :left, ->(**args) { Side::Component.new(position: :left, **args) }
      renders_one :right, ->(**args) { Side::Component.new(position: :right, **args) }
      renders_many :items, Item::Component

      # @deprecated Se elimina en 4.0. Level es una fila flex con `justify-between` y nada
      #   más, así que `<div class="flex justify-between items-center gap-4">` hace lo mismo
      #   sin componente de por medio. Para el encabezado de una página usa
      #   {Bali::PageHeader::Component}, que es lo que Level venía sosteniendo.
      def initialize(align: :center, **options)
        Bali.deprecator.warn(
          "Bali::Level::Component is deprecated. Use flex utilities " \
          "(`flex justify-between items-center gap-4`) for a plain row, or " \
          "Bali::PageHeader::Component for a page header."
        )
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
