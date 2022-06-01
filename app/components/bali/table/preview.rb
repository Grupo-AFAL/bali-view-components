# frozen_string_literal: true

module Bali
  module Table
    class Preview < ApplicationViewComponentPreview
      HEADERS = [
        { name: 'Name' },
        { name: 'Amount' }
      ].freeze
      RECORDS = [
        { name: 'Name 1', amount: 1 },
        { name: 'Name 2', amount: 2 },
        { name: 'Name 3', amount: 3 }
      ].freeze

      def default
        render_with_template(
          template: 'bali/table/previews/default',
          locals: {
            headers: HEADERS,
            records: RECORDS,
            query: nil
          }
        )
      end

      def empty_table
        render_with_template(
          template: 'bali/table/previews/default',
          locals: {
            headers: HEADERS,
            records: [],
            query: nil
          }
        )
      end

      def empty_search
        render_with_template(
          template: 'bali/table/previews/default',
          locals: {
            headers: HEADERS,
            records: [],
            query: { name: 'Name' }
          }
        )
      end
    end
  end
end
