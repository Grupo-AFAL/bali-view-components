# frozen_string_literal: true

module Bali
  module DashboardPage
    Stat = Data.define(:label, :value, :icon, :change, :color)

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

      # Se guardan los ARGUMENTOS y no el contenido renderizado porque cada stat es un
      # Bali::StatCard de verdad y su `change` entra por el slot `footer`. Mismo patrón que
      # `with_secondary_action`.
      def with_stat(label:, value:, icon: nil, change: nil, color: :primary)
        @stat_items << Stat.new(label: label, value: value, icon: icon, change: change, color: color)
      end

      private

      attr_reader :stat_items

      def stats_grid_classes
        columns = STATS_COLUMNS[@stats_columns] || STATS_COLUMNS[4]
        "grid grid-cols-1 #{columns} gap-4"
      end

      # La tabla de colores es la de StatCard: tener una propia acá es lo que produjo dos
      # tarjetas de estadística con dos paletas.
      def stat_change_class(color)
        palette = Bali::StatCard::Component::COLORS
        palette.fetch(color.to_sym, palette[:primary])[:text]
      end
    end
  end
end
