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

      # @label Bulk Actions
      # @description Select rows using checkboxes to see the floating action bar
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
