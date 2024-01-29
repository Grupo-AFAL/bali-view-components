# frozen_string_literal: true

require 'csv'
require 'simple_command'

module Bali
  module Commands
    class CsvExport
      prepend SimpleCommand

      include ActiveSupport::NumberHelper

      class << self
        attr_reader :export_klass, :columns

        # rubocop: disable Naming/AccessorMethodName
        def set_export_klass(value)
          @export_klass = value
        end
        # rubocop: enable Naming/AccessorMethodName

        def export_column(column_name, value: nil, format: nil)
          @columns ||= {}
          @columns[column_name] = { value: value, format: format }
        end
      end

      def initialize(records)
        @records = records
      end

      def call
        CSV.generate do |csv_file|
          csv_file << csv_headers

          @records.each do |record|
            csv_file << row_values(record)
          end
        end
      end

      def filename
        "#{export_klass.table_name}-#{Time.zone.today}.csv"
      end

      private

      def csv_headers
        columns.keys.map do |column_name|
          I18n.t("activerecord.attributes.#{export_klass.model_name.i18n_key}.#{column_name}")
        end
      end

      def row_values(record)
        columns.map do |column_name, options|
          column_value(record, column_name, options)
        end
      end

      def column_value(record, column_name, options)
        options => {value:, format:}

        column_value = value.present? ? record.instance_exec(&value) : record.send(column_name)

        return format_value(column_value, format) if format.is_a?(Symbol)

        column_value
      end

      def format_value(value, format)
        case format
        when :currency then number_to_currency(value, strip_insignificant_zeros: true)
        when :number then number_to_delimited(value)
        when :percentage then number_to_percentage(value)
        when :array then Array(value).join(', ')
        else value
        end
      end

      def export_klass
        self.class.export_klass
      end

      def columns
        self.class.columns
      end
    end
  end
end
