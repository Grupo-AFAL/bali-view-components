# frozen_string_literal: true

module Bali
  module DashboardPage
    Stat = Data.define(:label, :value, :icon, :change, :color)

    class Component < ApplicationViewComponent
      include PageComponents::Shared

      renders_many :actions
      renders_one :body

      MAX_WIDTHS = {
        lg: "max-w-5xl",
        xl: "max-w-7xl",
        "2xl": "max-w-screen-2xl",
        full: "max-w-full"
      }.freeze

      STAT_ICON_COLORS = {
        primary: "text-primary",
        secondary: "text-secondary",
        accent: "text-accent",
        success: "text-success",
        warning: "text-warning",
        error: "text-error",
        info: "text-info"
      }.freeze

      def initialize(title:, subtitle: nil, breadcrumbs: [], stats_columns: 4, max_width: :"2xl")
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
        @stats_columns = stats_columns
        @max_width = MAX_WIDTHS.fetch(max_width) do
          raise ArgumentError, "Unknown max_width: #{max_width.inspect}. Valid: #{MAX_WIDTHS.keys.join(', ')}"
        end
        @stat_items = []
      end

      def with_stat(label:, value:, icon: nil, change: nil, color: :primary)
        @stat_items << Stat.new(label: label, value: value, icon: icon, change: change, color: color)
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs, :stat_items, :max_width

      def stats_grid_classes
        cols = { 2 => "sm:grid-cols-2", 3 => "sm:grid-cols-3", 4 => "sm:grid-cols-2 lg:grid-cols-4" }
        "grid grid-cols-1 #{cols[@stats_columns] || cols[4]} gap-4"
      end

      def stat_icon_color(color)
        STAT_ICON_COLORS[color]
      end
    end
  end
end
