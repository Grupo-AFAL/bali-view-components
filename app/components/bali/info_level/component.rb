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

      # @deprecated Removed in 4.0. Every `InfoLevel::Item` is a stat card (label on top,
      #   large figure below) with a third design of its own; the one that stays is
      #   {Bali::StatCard::Component}, which is also what DashboardPage#with_stat has
      #   rendered since v3. For a row of figures, a grid of StatCard.
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
