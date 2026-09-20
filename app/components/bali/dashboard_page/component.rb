# frozen_string_literal: true

module Bali
  module DashboardPage
    Stat = Data.define(:label, :value, :icon, :change, :color, :href)

    class Component < ApplicationViewComponent
      include PageComponents::Shared

      # No `default_max_width` override: a dashboard inherits `:full` like the rest. The
      # `:"2xl"` cap it used to carry came from v2 and fought the container the host had
      # already chosen — a stats grid and a chart row are exactly the content that wants
      # the width the app gives it. A host that wants a cap still passes `max_width:`.

      STATS_COLUMNS = {
        2 => "sm:grid-cols-2",
        3 => "sm:grid-cols-3",
        4 => "sm:grid-cols-2 lg:grid-cols-4"
      }.freeze

      def initialize(stats_columns: 4, **options)
        super(**options)
        @stats_columns = stats_columns
        @stat_items = []
      end

      # The ARGUMENTS are stored and not the rendered content because every stat is a real
      # Bali::StatCard and its `change` comes in through the `footer` slot. Same pattern as
      # `with_secondary_action`. `href:` travels to the StatCard: the whole card becomes an
      # `<a>` (KPI drill-down → index).
      # rubocop:disable Metrics/ParameterLists
      def with_stat(label:, value:, icon: nil, change: nil, color: :primary, href: nil)
        @stat_items << Stat.new(label: label, value: value, icon: icon, change: change,
                                color: color, href: href)
      end
      # rubocop:enable Metrics/ParameterLists

      private

      attr_reader :stat_items

      def stats_grid_classes
        columns = STATS_COLUMNS[@stats_columns] || STATS_COLUMNS[4]
        "grid grid-cols-1 #{columns} gap-4"
      end

      # The color table is StatCard's: having one of its own here is what produced two stat
      # cards with two palettes.
      def stat_change_class(color)
        palette = Bali::StatCard::Component::COLORS
        palette.fetch(color.to_sym, palette[:primary])[:text]
      end
    end
  end
end
