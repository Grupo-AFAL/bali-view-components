# frozen_string_literal: true

module Bali
  module DataTable
    class Preview < ApplicationViewComponentPreview
      FORM = Bali::Utils::DummyFilterForm.new

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
          template: 'bali/data_table/previews/default',
          locals: {
            headers: HEADERS,
            records: RECORDS,
            form: FORM
          }
        )
      end

      def with_summary
        render_with_template(
          template: 'bali/data_table/previews/default',
          locals: {
            headers: HEADERS,
            records: RECORDS,
            form: FORM,
            summary: 'This is a summary'
          }
        )
      end

      def with_custom_filters_layout
        render_with_template(
          template: 'bali/data_table/previews/custom_filters_layout',
          locals: {
            headers: HEADERS,
            records: RECORDS,
            form: FORM
          }
        )
      end
    end
  end
end
