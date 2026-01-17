# frozen_string_literal: true

module Bali
  module AdvancedFilters
    class Component < ApplicationViewComponent
      include Utils::Url

      attr_reader :url, :available_attributes, :apply_mode, :id, :popover, :combinator,
                  :filter_groups, :max_groups

      # Renders the applied filter pills above the filter builder
      renders_one :applied_tags, ->(**options) do
        AppliedTags::Component.new(
          filter_groups: @filter_groups,
          available_attributes: @available_attributes,
          url: @url,
          **options
        )
      end

      # @param url [String] The URL to submit filters to
      # @param available_attributes [Array<Hash>] Available filterable attributes
      #   Each hash should have: { key:, label:, type:, options: (for select) }
      #   Types: :text, :number, :date, :datetime, :select, :boolean
      # @param filter_groups [Array<Hash>] Initial filter state (from URL params)
      # @param apply_mode [Symbol] :batch (default) or :live
      # @param combinator [Symbol] :and (default) or :or - how groups are combined
      # @param max_groups [Integer] Maximum number of filter groups allowed
      # @param popover [Boolean] Whether to show filters in a popover (default: true)
      # @param button_text [String] Text for the popover trigger button
      # @param search [Hash] Quick search configuration
      #   - :fields [Array<Symbol>] Fields to search (e.g., [:name, :description])
      #   - :value [String] Current search value from URL params
      #   - :placeholder [String] Placeholder text for search input
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        url:,
        available_attributes:,
        filter_groups: [],
        apply_mode: :batch,
        combinator: :and,
        max_groups: 10,
        popover: true,
        button_text: nil,
        search: {},
        **options
      )
        @url = url
        @available_attributes = normalize_attributes(available_attributes)
        @filter_groups = filter_groups.presence || [default_filter_group]
        @apply_mode = apply_mode
        @combinator = combinator.to_s
        @max_groups = max_groups
        @popover = popover
        @button_text = button_text
        @search = search || {}
        @id = options[:id] || "advanced-filters-#{SecureRandom.hex(4)}"
      end
      # rubocop:enable Metrics/ParameterLists

      def button_text
        @button_text || I18n.t('bali.advanced_filters.filters_button', default: 'Filters')
      end

      def search_enabled?
        @search[:fields].present?
      end

      def search_value
        @search[:value]
      end

      def search_placeholder
        @search[:placeholder] || I18n.t('bali.advanced_filters.search_placeholder',
                                        default: 'Search...')
      end

      # Build Ransack field name for multi-field search (e.g., "name_or_genre_cont")
      def search_field_name
        return nil unless search_enabled?

        fields = @search[:fields].map(&:to_s).join('_or_')
        "q[#{fields}_cont]"
      end

      def active_filter_count
        @filter_groups.sum do |group|
          group[:conditions]&.count { |c| c[:attribute].present? && c[:value].present? } || 0
        end
      end

      def active_filters?
        active_filter_count.positive?
      end

      # Serialize attributes for Stimulus controller
      def attributes_json
        @available_attributes.map do |attr|
          {
            key: attr[:key].to_s,
            label: attr[:label],
            type: attr[:type].to_s,
            options: attr[:options] || [],
            operators: operators_for_type(attr[:type])
          }
        end.to_json
      end

      # Build the default operators for each attribute type.
      # Delegates to Operators module for centralized definitions.
      def operators_for_type(type)
        Operators.for_type(type)
      end

      private

      def normalize_attributes(attributes)
        attributes.map do |attr|
          {
            key: attr[:key],
            label: attr[:label] || attr[:key].to_s.humanize,
            type: attr[:type] || :text,
            options: attr[:options] || []
          }
        end
      end

      def default_filter_group
        {
          combinator: 'or',
          conditions: [default_condition]
        }
      end

      def default_condition
        {
          attribute: '',
          operator: 'cont',
          value: ''
        }
      end
    end
  end
end
