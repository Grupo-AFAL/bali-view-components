# frozen_string_literal: true

module Bali
  module Table
    class Preview < ApplicationViewComponentPreview
      HEADERS = [
        { name: 'Name' },
        { name: 'Amount' }
      ].freeze

      RECORDS = [
        { id: 1, name: 'Name 1', amount: 1 },
        { id: 2, name: 'Name 2', amount: 2 },
        { id: 3, name: 'Name 3', amount: 3 }
      ].freeze

      BULK_ACTION_HEADERS = [
        { name: 'Product' },
        { name: 'SKU' },
        { name: 'Price' },
        { name: 'Stock' },
        { name: 'Status' }
      ].freeze

      GROUPING_HEADERS = [
        { name: 'Leader' },
        { name: 'Role' },
        { name: 'Members' }
      ].freeze

      # Pre-sorted by area — grouping assumes caller-controlled row order.
      GROUPING_RECORDS = [
        { id: 1, area: 'Norte', leader: 'Ana Torres', role: 'Coordinator', members: 12 },
        { id: 2, area: 'Norte', leader: 'Bruno Díaz', role: 'Volunteer', members: 4 },
        { id: 3, area: 'Norte', leader: 'Carla Ruiz', role: 'Volunteer', members: 6 },
        { id: 4, area: 'Norte', leader: 'Diego Sosa', role: 'Volunteer', members: 3 },
        { id: 5, area: 'Centro', leader: 'Elena Vidal', role: 'Coordinator', members: 15 },
        { id: 6, area: 'Centro', leader: 'Fabián Mora', role: 'Volunteer', members: 5 },
        { id: 7, area: 'Centro', leader: 'Gabriela León', role: 'Volunteer', members: 8 },
        { id: 8, area: 'Centro', leader: 'Hugo Peña', role: 'Volunteer', members: 2 },
        { id: 9, area: 'Sur', leader: 'Irene Campos', role: 'Coordinator', members: 10 },
        { id: 10, area: 'Sur', leader: 'Julián Rojas', role: 'Volunteer', members: 7 },
        { id: 11, area: 'Sur', leader: 'Karina Vega', role: 'Volunteer', members: 9 },
        { id: 12, area: 'Sur', leader: 'Lucas Ibarra', role: 'Volunteer', members: 1 }
      ].freeze

      BULK_ACTION_RECORDS = [
        { id: 1, product: 'MacBook Pro 14"', sku: 'MBP-14-M3', price: '$1,999', stock: 45, status: 'active' },
        { id: 2, product: 'iPhone 15 Pro', sku: 'IP15-PRO-256', price: '$999', stock: 120, status: 'active' },
        { id: 3, product: 'iPad Air', sku: 'IPAD-AIR-M2', price: '$599', stock: 0, status: 'out_of_stock' },
        { id: 4, product: 'AirPods Pro', sku: 'APP-2ND-GEN', price: '$249', stock: 200, status: 'active' },
        { id: 5, product: 'Apple Watch Ultra', sku: 'AW-ULTRA-49', price: '$799', stock: 15, status: 'low_stock' },
        { id: 6, product: 'Mac Mini M2', sku: 'MM-M2-512', price: '$799', stock: 30, status: 'active' },
        { id: 7, product: 'Studio Display', sku: 'SD-27-5K', price: '$1,599', stock: 8, status: 'low_stock' }
      ].freeze

      def default
        render_with_template(
          template: 'bali/table/previews/default',
          locals: {
            headers: HEADERS,
            records: RECORDS
          }
        )
      end

      def empty_table
        render_with_template(
          template: 'bali/table/previews/default',
          locals: {
            headers: HEADERS,
            records: []
          }
        )
      end

      def with_custom_no_records_notification
        render_with_template(
          template: 'bali/table/previews/with_custom_no_records_notification',
          locals: {
            headers: HEADERS,
            records: []
          }
        )
      end

      # @label With Grouping
      # Pass `group:` to `with_row` to render a group-header row whenever the
      # value changes between consecutive rows. The header shows the group value
      # and the count of rows in that run (e.g. "Norte (4)").
      #
      # The collection must arrive **pre-sorted by the group field** — the
      # component never re-orders rows. The same value reappearing later starts a
      # new group. Grouping is therefore incompatible with user-driven column
      # sorting, and a group may continue across Pagy page boundaries.
      def with_grouping
        render_with_template(
          template: 'bali/table/previews/with_grouping',
          locals: {
            headers: GROUPING_HEADERS,
            records: GROUPING_RECORDS
          }
        )
      end

      # @label Bulk Actions
      # Select rows using checkboxes to see the floating action bar.
      # The bulk actions container appears when at least one row is selected.
      def bulk_actions
        render_with_template(
          template: 'bali/table/previews/bulk_actions',
          locals: {
            headers: BULK_ACTION_HEADERS,
            records: BULK_ACTION_RECORDS
          }
        )
      end
    end
  end
end
