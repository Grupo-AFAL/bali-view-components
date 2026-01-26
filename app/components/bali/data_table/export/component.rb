# frozen_string_literal: true

module Bali
  module DataTable
    module Export
      class Component < ApplicationViewComponent
        # Supported export formats with their icons and extensions
        FORMATS = {
          csv: { icon: 'file-export', extension: 'csv' },
          excel: { icon: 'file-export', extension: 'xlsx' },
          pdf: { icon: 'file-export', extension: 'pdf' },
          json: { icon: 'file-export', extension: 'json' }
        }.freeze

        # @param formats [Array<Symbol>] Export formats to show (e.g., [:csv, :excel, :pdf])
        # @param url [String] Base URL for export (required - format param will be appended)
        # @param button_label [String] Label for the dropdown button (i18n default)
        # @param button_icon [String] Icon name (default: 'download')
        # @param method [Symbol] HTTP method for export links (default: :get)
        def initialize(formats: %i[csv excel pdf], url: nil, button_label: nil,
                       button_icon: 'download', method: :get)
          @formats = formats.map(&:to_sym)
          @url = url
          @button_label = button_label
          @button_icon = button_icon
          @method = method
        end

        attr_reader :formats, :button_icon, :method

        def button_label
          @button_label || t('.button_label')
        end

        def export_items
          formats.filter_map do |format|
            config = FORMATS[format]
            next unless config

            {
              url: export_url(format),
              icon: config[:icon],
              label: format_label(format),
              format: format
            }
          end
        end

        private

        def format_label(format)
          t(".formats.#{format}")
        end

        def export_url(format)
          base = @url || '/export'
          separator = base.include?('?') ? '&' : '?'
          "#{base}#{separator}format=#{format}"
        end
      end
    end
  end
end
