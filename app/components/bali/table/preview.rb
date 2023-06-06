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

      def bulk_actions
        render_with_template(
          template: 'bali/table/previews/bulk_actions',
          locals: {
            headers: HEADERS,
            records: RECORDS
          }
        )
      end
    end
  end
end
