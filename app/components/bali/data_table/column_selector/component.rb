# frozen_string_literal: true

module Bali
  module DataTable
    module ColumnSelector
      class Component < ApplicationViewComponent
        include Bali::DataTable::ListingIdentity

        # Simple struct for column data
        Column = Struct.new(:index, :label, :visible, :key, keyword_init: true) do
          # How the device memory and a saved view name the column: its key when it has one,
          # its position otherwise.
          def id = key || index
        end

        # The same pattern as COLUMN_KEY in column_storage.js, which drops any other key from
        # the device memory without a word. Keys are told from positions by type, and a payload
        # that went through a form comes back as strings, so a key cannot start with a digit.
        KEY = /\A[A-Za-z_][\w-]{0,63}\z/
        POSITION = /\A\d+\z/

        # The column ids of a saved view's payload: Integers are positions, Strings are keys,
        # and anything else is dropped.
        def self.column_ids(values)
          Array(values).filter_map do |value|
            case value.to_s
            when POSITION then value.to_i
            when KEY then value.to_s
            end
          end
        end

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

        # Imposes the visibility from a saved view: visible = the given column ids.
        # Called AFTER the with_column block (the DataTable does it on its own).
        #
        # A view saved before the host declared keys carries positions only, and position is
        # all it can mean: then every column is matched by its index, keyed or not.
        def apply_visible_columns(ids)
          visible = self.class.column_ids(ids)
          positional = visible.none?(String)

          @columns.each do |column|
            column.visible = visible.include?(positional ? column.index : column.id)
          end
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
        # @param key [String, Symbol, nil] Stable name the device memory and saved views use
        #   instead of the index, so inserting a column does not shift what users saved.
        #   A letter or `_` first, then letters, digits, `_` or `-`; 64 characters at most.
        def with_column(index:, label:, visible: true, key: nil)
          key = key.to_s.presence
          if key && !key.match?(KEY)
            raise ArgumentError, "column key #{key.inspect} must start with a letter or _ and use " \
                                 "only letters, digits, _ or - (64 at most)"
          end
          raise ArgumentError, "duplicate column key #{key.inspect}" if key && @columns.any? { it.key == key }

          @columns << Column.new(index: index, label: label, visible: visible, key: key)
        end
      end
    end
  end
end
