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

        def export_column(column_name, value: nil, style: nil, footer: nil, format: nil)
          @columns[column_name] = { value: value, style: style, footer: footer, format: format }
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
        xlsx.workbook.escape_formulas = escape_formulas
        styles = xlsx.workbook.styles

        self.class.sheets.each do |sheet|
          workbook_sheet = xlsx.workbook.add_worksheet(name: sheet.name)
          sheet_row_styles = row_styles(sheet.columns, styles)

          workbook_sheet.add_row(headers(sheet))
          @records.each do |record|
            workbook_sheet.add_row(row_values(sheet.columns, record), style: sheet_row_styles)
          end

          workbook_sheet.add_row(footer_values(sheet.columns), style: sheet_row_styles)
        end

        xlsx.use_shared_strings = true
        [@filename || default_filename, xlsx.to_stream.string]
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
        columns.map do |column_name, options|
          options => {value:}
          value.present? ? record.instance_exec(&value) : record.send(column_name)
        end
      end

      def default_filename
        "#{export_klass.table_name}-#{Time.zone.today}.xlsx"
      end

      def export_klass
        self.class.export_klass
      end

      def escape_formulas
        !!self.class.escape_formulas
      end

      def row_styles(columns, wb_styles)
        columns.map do |_, opts|
          opts => { style:, format: }
          format_code_from_format = format_codes[format]
          next if style.blank? && format_code_from_format.blank?

          wb_styles.add_style(**(format_code_from_format.presence || style))
        end
      end

      def format_codes
        {
          currency: { format_code: '$#,##0_);($#,##0)' },
          percentage: { format_code: '0%' }
        }
      end
    end
  end
end
