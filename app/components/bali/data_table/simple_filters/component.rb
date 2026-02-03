# frozen_string_literal: true

module Bali
  module DataTable
    module SimpleFilters
      # SimpleFilters provides inline dropdown filters for DataTable.
      # Unlike the complex Filters component, SimpleFilters renders as a simple
      # row of select dropdowns with a submit button - no popovers, no AND/OR
      # groupings, no operator selection.
      #
      # @example Via DataTable slot (auto-configured from FilterForm)
      #   data_table.with_simple_filters
      #
      # @example With explicit filters
      #   data_table.with_simple_filters(filters: [
      #     { attribute: :status, collection: [...], blank: "All", label: "Status" }
      #   ])
      #
      class Component < ApplicationViewComponent
        # @param url [String] Form submission URL
        # @param filters [Array<Hash>] Filter configurations
        # @param show_clear [Boolean] Show clear button
        def initialize(url:, filters:, show_clear: false)
          @url = url
          @filters = filters || []
          @show_clear = show_clear
        end

        def render?
          @filters.any?
        end

        def show_clear_button?
          @show_clear
        end

        def filter_field_name(attribute)
          "q[#{attribute}_eq]"
        end

        def apply_button_text
          I18n.t('bali.simple_filters.apply', default: 'Filter')
        end

        def clear_button_text
          I18n.t('bali.simple_filters.clear', default: 'Clear')
        end
      end
    end
  end
end
