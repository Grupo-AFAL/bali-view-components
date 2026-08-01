# frozen_string_literal: true

module Bali
  module InfoLevel
    class Component < ApplicationViewComponent
      ALIGNMENTS = {
        start: "justify-start",
        center: "justify-center",
        end: "justify-end",
        between: "justify-between"
      }.freeze

      BASE_CLASSES = "info-level-component flex flex-wrap gap-8"

      renders_many :items, Item::Component

      # @deprecated Se elimina en 4.0. Cada `InfoLevel::Item` es una tarjeta de estadística
      #   (rótulo arriba, cifra grande abajo) con un tercer diseño propio; el que queda es
      #   {Bali::StatCard::Component}, que es también el que DashboardPage#with_stat pinta
      #   desde v3. Para una fila de cifras, una grilla de StatCard.
      def initialize(align: :center, **options)
        Bali.deprecator.warn(
          "Bali::InfoLevel::Component is deprecated. Use a grid of " \
          "Bali::StatCard::Component, which is what Bali::DashboardPage#with_stat renders."
        )
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
