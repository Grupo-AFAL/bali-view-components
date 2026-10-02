# frozen_string_literal: true

module Bali
  module DataTable
    # The export links of the page's ⋯ (`with_export`), one per format, each carrying the
    # slice the user is looking at. Their other half is `export_links_controller.js`, which
    # re-syncs these hrefs from the browser URL after a filter submit.
    class ExportLinks
      include ToolbarHref

      FORMATS = %i[csv excel pdf json].freeze

      # @param url [String] Base URL of the listing, without `format`
      # @param formats [Array<Symbol>] Formats to offer; any outside FORMATS is skipped
      # @param params [Hash] Slice the links carry; `{}` exports everything
      def initialize(url:, formats:, params:)
        @url = url
        @formats = formats.map(&:to_sym)
        @params = params
      end

      # @return [Array<Hash>] `{ url:, label: }` per format, in the order given
      def items
        (@formats & FORMATS).map do |format|
          { url: build_toolbar_href(@url, @params, :format, format),
            label: I18n.t("bali_view.data_table.export.formats.#{format}") }
        end
      end
    end
  end
end
