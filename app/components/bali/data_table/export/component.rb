# frozen_string_literal: true

module Bali
  module DataTable
    module Export
      class Component < ApplicationViewComponent
        include Bali::DataTable::ToolbarHref

        # Supported export formats with their icons and extensions
        FORMATS = {
          csv: { icon: "file-export", extension: "csv" },
          excel: { icon: "file-export", extension: "xlsx" },
          pdf: { icon: "file-export", extension: "pdf" },
          json: { icon: "file-export", extension: "json" }
        }.freeze

        # @param formats [Array<Symbol>] Export formats to show (e.g., [:csv, :excel, :pdf])
        # @param url [String] Base URL for export (required - format param will be appended)
        # @param params [Hash, nil] Recorte activo que el link tiene que arrastrar. `nil` lo
        #   lee del request; `{}` es el opt-out explícito (exportar todo a propósito).
        # @param button_label [String] Label for the dropdown button (i18n default)
        # @param button_icon [String] Icon name (default: 'download')
        def initialize(formats: %i[csv excel pdf], url: nil, params: nil, button_label: nil,
                       button_icon: "download")
          @formats = formats.map(&:to_sym)
          @url = url
          @params = params
          @button_label = button_label
          @button_icon = button_icon
        end

        attr_reader :formats, :button_icon

        def button_label
          @button_label || t(".button_label")
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

        # Clave ABSOLUTA y no `t('.formats.x')`: el ⋯ del PageHeader CONSTRUYE este componente
        # y le lee `export_items` sin renderizarlo nunca, y el helper de traducción de
        # ViewComponent necesita contexto de render. Es la misma clave que resolvía antes, así
        # que un host que la tenga sobrescrita no se entera.
        def format_label(format)
          I18n.t("view_components.bali.data_table.export.formats.#{format}")
        end

        # El export se lleva EL MISMO recorte que el usuario está mirando: filtros, búsqueda,
        # orden, agrupación y la vista guardada aplicada. Antes era `url + "?format=x"`, y
        # como el host pasa un path pelado el usuario filtraba a 3 filas, exportaba y se
        # llevaba 20, en silencio. Se arma con el helper compartido de la toolbar por dos
        # razones más: la `url:` del host PUEDE traer query string (y un "?" a secas la
        # corrompía), y TRANSIENT_PARAMS es lo que evita que el link arrastre `page`
        # —exportaría una página— o `clear_filters`, que en el server borra los filtros
        # guardados del usuario como efecto secundario del click.
        def export_url(format)
          build_toolbar_href(@url || "/export", @params || request_query_params, :format, format)
        end
      end
    end
  end
end
