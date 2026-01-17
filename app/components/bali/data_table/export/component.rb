# frozen_string_literal: true

module Bali
  module DataTable
    module Export
      class Component < ApplicationViewComponent
        # Supported export formats with their icons and labels
        FORMATS = {
          csv: { icon: 'file-export', label: 'CSV', extension: 'csv' },
          excel: { icon: 'file-export', label: 'Excel', extension: 'xlsx' },
          pdf: { icon: 'file-export', label: 'PDF', extension: 'pdf' },
          json: { icon: 'file-export', label: 'JSON', extension: 'json' }
        }.freeze

        # @param formats [Array<Symbol>] Export formats to show (e.g., [:csv, :excel, :pdf])
        # @param url [String] Base URL for export (format param will be appended)
        #   If nil, uses current URL with format param
        # @param button_label [String] Label for the dropdown button (default: 'Export')
        # @param button_icon [String] Icon name (default: 'download')
        # @param method [Symbol] HTTP method for export links (default: :get)
        def initialize(formats: %i[csv excel pdf], url: nil, button_label: 'Export',
                       button_icon: 'download', method: :get)
          @formats = formats.map(&:to_sym)
          @url = url
          @button_label = button_label
          @button_icon = button_icon
          @method = method
        end

        attr_reader :formats, :button_label, :button_icon, :method

        def export_items
          formats.filter_map do |format|
            config = FORMATS[format]
            next unless config

            {
              url: export_url(format),
              icon: config[:icon],
              label: config[:label],
              format: format
            }
          end
        end

        private

        def export_url(format)
          base = @url || helpers.request.path
          separator = base.include?('?') ? '&' : '?'
          "#{base}#{separator}format=#{format}"
        end
      end
    end
  end
end
