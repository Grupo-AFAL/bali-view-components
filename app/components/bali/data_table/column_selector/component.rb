# frozen_string_literal: true

module Bali
  module DataTable
    module ColumnSelector
      class Component < ApplicationViewComponent
        include Bali::DataTable::ListingIdentity

        # Simple struct for column data
        Column = Struct.new(:index, :label, :visible, keyword_init: true)

        # @param listing_id [String] Identity of the listing (the id of the DataTable
        #   container, which resolves it). Both the columns target (`#<listing_id> table`)
        #   and the localStorage key are derived from it.
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

        # Is the visibility imposed by the server (a saved view applied)? The JS then does
        # NOT restore localStorage on top — the view wins.
        def server_state? = @server_state

        def persist? = @persist

        # Imposes the visibility from a saved view: visible = the given indices.
        # Called AFTER the with_column block (the DataTable does it on its own).
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
