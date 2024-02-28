# frozen_string_literal: true

require 'caxlsx'
require 'simple_command'

module Bali
  module Commands
    class XlsxExport
      prepend SimpleCommand

      class Sheet
        attr_reader :name, :columns

        def initialize(name)
          @name = name
          @columns = {}
        end

        def export_column(column_name, value: nil, footer: nil, format: nil)
          @columns[column_name] = { value: value, footer: footer, format: format }
        end
      end

      class << self
        attr_reader :export_klass, :escape_formulas, :sheets

        # rubocop: disable Naming/AccessorMethodName
        def set_export_klass(value)
          @export_klass = value
        end

        def set_escape_formulas(value)
          @escape_formulas = value
        end
        # rubocop: enable Naming/AccessorMethodName

        def sheet(name)
          @sheets ||= []
          new_sheet = Sheet.new(name)
          @sheets << new_sheet

          yield(new_sheet)
        end
      end

      def initialize(records, filename)
        @records = records
        @filename = filename
      end

      def call
        xlsx = ::Axlsx::Package.new

        self.class.sheets.each do |sheet|
          workbook_sheet = xlsx.workbook.add_worksheet(name: sheet.name)

          workbook_sheet.add_row(headers(sheet))
          @records.each do |record|
            workbook_sheet.add_row(row_values(sheet.columns, record))
          end
          workbook_sheet.add_row(footer_values(sheet.columns))
        end

        xlsx.use_shared_strings = true
        xlsx_string = xlsx.to_stream.string

        [@filename || default_filename, xlsx_string]
      end

      private

      def headers(sheet)
        sheet.columns.keys.map do |column_name|
          I18n.t("activerecord.attributes.#{export_klass.model_name.i18n_key}.#{column_name}")
        end
      end

      def footer_values(columns)
        columns.map do |_, options|
          next if options[:footer].blank?

          options[:footer].call
        end
      end

      def row_values(columns, record)
        columns.map { |column_name, options| column_value(record, column_name, options) }
      end

      def column_value(record, column_name, options)
        options => {value:, format:}

        column_value = value.present? ? record.instance_exec(&value) : record.send(column_name)

        return format_value(column_value, format) if format.is_a?(Symbol)

        column_value
      end

      def format_value(value, format)
        case format
        when :currency then "$ #{value.round(2)}"
        when :number then number_to_delimited(value)
        when :percentage then number_to_percentage(value)
        when :array then Array(value).join(', ')
        else value
        end
      end

      def default_filename
        "#{export_klass.table_name}-#{Time.zone.today}.xlsx"
      end

      def export_klass
        self.class.export_klass
      end
    end
  end
end
