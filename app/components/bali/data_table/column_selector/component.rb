# frozen_string_literal: true

module Bali
  module DataTable
    module ColumnSelector
      class Component < ApplicationViewComponent
        include Bali::DataTable::ListingIdentity

        # Simple struct for column data
        Column = Struct.new(:index, :label, :visible, keyword_init: true)

        # @param listing_id [String] Identidad del listado (el id del contenedor del
        #   DataTable, que la resuelve). De ella se derivan el target de las columnas
        #   (`#<listing_id> table`) y la llave de localStorage.
        # @param button_label [String] Label for the dropdown button (i18n default)
        # @param button_icon [String] Icon name (default: 'table')
        # @param persist [Boolean] Persist column visibility in localStorage keyed by
        #   listing_id (per-device, B2/FB-17). Default: true.
        def initialize(listing_id:, button_label: nil, button_icon: "table", persist: true)
          @listing_id = listing_id.to_s.delete_prefix("#")
          @button_label = button_label
          @button_icon = button_icon
          @persist = persist
          @server_state = false
          @columns = []
        end

        attr_reader :listing_id, :button_icon, :columns

        # ¿La visibilidad viene impuesta por el servidor (vista guardada aplicada)? El JS
        # entonces NO restaura localStorage encima — la vista manda.
        def server_state? = @server_state

        def persist? = @persist

        # Impone la visibilidad desde una vista guardada: visibles = los índices dados.
        # Se llama DESPUÉS del bloque de with_column (el DataTable lo hace solo).
        def apply_visible_columns(indices)
          visible = Array(indices).map(&:to_i)
          @columns.each { |column| column.visible = visible.include?(column.index) }
          @server_state = true
        end

        def button_label
          @button_label || t(".button_label")
        end

        def menu_title
          t(".menu_title")
        end

        # Add a column to the selector
        # @param index [Integer] Column index in the table (0-based)
        # @param label [String] Display label for the column
        # @param visible [Boolean] Whether the column is visible by default
        def with_column(index:, label:, visible: true)
          @columns << Column.new(index: index, label: label, visible: visible)
        end
      end
    end
  end
end
