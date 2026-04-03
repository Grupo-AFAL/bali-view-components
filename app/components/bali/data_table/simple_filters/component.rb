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
        # @param search [Hash, nil] Search input configuration
        #   - :field_name [String] Ransack param name (e.g., "q[name_cont]")
        #   - :value [String, nil] Current search value
        #   - :placeholder [String, nil] Placeholder text
        #   - :label [String, nil] Custom label (defaults to I18n)
        def initialize(url:, filters: [], show_clear: false, search: nil)
          @url = url
          @filters = filters
          @show_clear = show_clear
          @search = search
        end

        def render?
          @filters.any? || search_enabled?
        end

        def show_clear_button?
          @show_clear
        end

        def search_enabled?
          @search.present? && @search[:field_name].present?
        end

        def search_label
          @search[:label] || I18n.t("bali.simple_filters.search", default: "Search")
        end

        def toggle_group?(filter)
          filter[:type]&.to_sym == :toggle_group
        end

        def slim_select?(filter)
          filter[:type]&.to_sym == :slim_select
        end

        def date?(filter)
          filter[:type]&.to_sym == :date
        end

        def date_range?(filter)
          filter[:type]&.to_sym == :date_range
        end

        def filter_field_name(filter)
          predicate = filter[:predicate] || (date_range?(filter) ? nil : :eq)
          name = predicate.present? ? "q[#{filter[:attribute]}_#{predicate}]" : "q[#{filter[:attribute]}]"
          toggle_group?(filter) ? "#{name}[]" : name
        end

        def apply_button_text
          I18n.t("bali.simple_filters.apply", default: "Filter")
        end

        def clear_button_text
          I18n.t("bali.simple_filters.clear", default: "Clear")
        end
      end
    end
  end
end
