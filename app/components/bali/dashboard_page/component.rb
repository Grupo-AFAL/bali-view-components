# frozen_string_literal: true

module Bali
  module DashboardPage
    class Component < ApplicationViewComponent
      renders_many :actions
      renders_one :body

      Stat = Struct.new(:label, :value, :icon, :change, :color, keyword_init: true)

      def initialize(title:, subtitle: nil, breadcrumbs: [], stats_columns: 4, **options)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs
        @stats_columns = stats_columns
        @options = options
        @stats = []
      end

      def with_stat(label:, value:, icon: nil, change: nil, color: :primary, **options)
        @stats << Stat.new(label: label, value: value, icon: icon, change: change, color: color, **options)
      end

      def stats
        @stats
      end

      def stats?
        @stats.any?
      end

      def stats_grid_classes
        cols = { 2 => "sm:grid-cols-2", 3 => "sm:grid-cols-3", 4 => "sm:grid-cols-2 lg:grid-cols-4" }
        "grid grid-cols-1 #{cols[@stats_columns] || cols[4]} gap-4"
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs
    end
  end
end
