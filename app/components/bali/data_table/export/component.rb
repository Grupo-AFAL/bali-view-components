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
        # @param params [Hash, nil] Active slice the link has to carry along. `nil` reads it
        #   from the request; `{}` is the explicit opt-out (exporting everything on purpose).
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

        # See `export_links_controller.js`: the re-sync from the URL only holds when the
        # slice came from the request. With an explicit `params:` (or `{}`, the opt-out) the
        # href is the host's decision, and guessing it undoes that decision in silence.
        def sync_links?
          @params.nil?
        end

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

        # ABSOLUTE key and not `t('.formats.x')`: the PageHeader's ⋯ BUILDS this component and
        # reads `export_items` off it without ever rendering it, and ViewComponent's
        # translation helper needs a render context. It is the same key that resolved before,
        # so a host that has it overridden notices nothing.
        def format_label(format)
          I18n.t("bali_view.data_table.export.formats.#{format}")
        end

        # The export takes THE SAME slice the user is looking at: filters, search, sorting,
        # grouping and the applied saved view. It used to be `url + "?format=x"`, and since
        # the host passes a bare path the user filtered down to 3 rows, exported, and got 20,
        # in silence. It is built with the toolbar's shared helper for two more reasons: the
        # host's `url:` CAN carry a query string (and a plain "?" corrupted it), and
        # TRANSIENT_PARAMS is what keeps the link from dragging `page` —it would export one
        # page— or `clear_filters`, which on the server deletes the user's saved filters as a
        # side effect of the click.
        def export_url(format)
          build_toolbar_href(@url || "/export", @params || request_query_params, :format, format)
        end
      end
    end
  end
end
