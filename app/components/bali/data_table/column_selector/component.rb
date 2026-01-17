# frozen_string_literal: true

module Bali
  module DataTable
    module ColumnSelector
      class Component < ApplicationViewComponent
        # Simple struct for column data
        Column = Struct.new(:index, :label, :visible, keyword_init: true)

        # @param table_id [String] CSS selector for the target table (e.g., '#my-table')
        # @param button_label [String] Label for the dropdown button (default: 'Columns')
        # @param button_icon [String] Icon name (default: 'table')
        def initialize(table_id:, button_label: 'Columns', button_icon: 'table')
          @table_id = table_id.start_with?('#') ? table_id : "##{table_id}"
          @button_label = button_label
          @button_icon = button_icon
          @columns = []
        end

        attr_reader :table_id, :button_label, :button_icon, :columns

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
