# frozen_string_literal: true

module Bali
  module BarList
    class Preview < ApplicationViewComponentPreview
      # One row per item: the label, the figure at the end of its line, and a track filled in
      # proportion to the largest value. A row with `href:` is a single link — label and figure
      # are its name — and the track is hidden from assistive tech. The list grows with its rows;
      # at 12, the last one has no link, as a job profile the viewer may not open.
      #
      # @param rows select [3, 12]
      # @param links toggle
      # @param color select [primary, secondary, accent, info, success, warning, error, neutral, ghost]
      def default(rows: 3, links: true, color: :primary)
        render Bali::BarList::Component.new(
          aria_label: "People by job profile", color: color.to_sym,
          items: Bali::BarList::Preview.job_profiles(rows.to_i, links: links)
        )
      end

      # Labels longer than their line wrap under themselves; the figure keeps its place at the
      # end of the first line.
      def long_labels
        render Bali::BarList::Component.new(aria_label: "People by job profile", items: [
          { label: "GERENTE DE RESTAURANTE CARL'S", value: 14, href: "/lookbook" },
          { label: "SUPERVISOR DE ALIMENTOS Y BEBIDAS DEL CENTRO DE DISTRIBUCIÓN NORTE", value: 9, href: "/lookbook" },
          { label: "COORDINADORA REGIONAL DE OPERACIONES BAJA CALIFORNIA", value: 3 }
        ])
      end

      # `format:` writes the figure's text — here with its unit.
      def formatted
        render Bali::BarList::Component.new(
          aria_label: "Lunches by dish", format: ->(count) { "#{count} lunches" },
          items: [ { label: "Enchiladas suizas", value: 31 }, { label: "Sopa de tortilla", value: 18 },
                   { label: "Chiles rellenos de queso con arroz y frijoles", value: 7 } ]
        )
      end

      JOB_PROFILES = [
        [ "GERENTE DE RESTAURANTE CARL'S", 12 ], [ "COCINERO", 9 ], [ "CAJERO", 7 ],
        [ "AUXILIAR DE COCINA", 6 ], [ "ANFITRIONA", 5 ], [ "LAVALOZA", 4 ], [ "BARISTA", 4 ],
        [ "SUBGERENTE", 3 ], [ "REPARTIDOR", 2 ], [ "ALMACENISTA", 2 ], [ "MESERO", 1 ], [ "Sin puesto", 1 ]
      ].freeze

      def self.job_profiles(count, links:)
        Bali::BarList::Preview::JOB_PROFILES.first(count).each_with_index.map do |(label, value), index|
          href = "/lookbook?profile=#{index}" if links && label != "Sin puesto"
          { label: label, value: value, href: href }
        end
      end
    end
  end
end
