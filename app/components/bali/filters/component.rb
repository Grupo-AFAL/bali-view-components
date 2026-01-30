# frozen_string_literal: true

module Bali
  module Filters
    class Component < ApplicationViewComponent
      EXCLUDED_PARAMS = %w[q clear_filters clear_search].freeze

      attr_reader :url, :available_attributes, :apply_mode, :id, :popover, :combinator,
                  :filter_groups, :max_groups, :storage_id, :persist_enabled, :turbo_stream

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
      # @param storage_id [String] Optional storage ID indicating filters can be persisted
      # @param persist_enabled [Boolean] Whether user has opted into filter persistence
      # @param turbo_stream [Boolean] Whether to accept Turbo Stream responses (default: false)
      #   When true, forms will include data-turbo-stream="true" to accept stream responses.
      #   The URL is still updated via JavaScript before form submission.
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
        storage_id: nil,
        persist_enabled: false,
        turbo_stream: false,
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
        @storage_id = storage_id
        @persist_enabled = persist_enabled
        @turbo_stream = turbo_stream
        @id = options[:id] || "filters-#{SecureRandom.hex(4)}"
      end
      # rubocop:enable Metrics/ParameterLists

      # Returns true if persistence is available (storage_id is configured)
      def persistence_available?
        @storage_id.present?
      end

      # Returns true if user has enabled persistence
      def persist_enabled?
        @persist_enabled
      end

      def button_text
        @button_text || I18n.t('bali.filters.filters_button', default: 'Filters')
      end

      def search_enabled?
        @search[:fields].present?
      end

      def search_value
        @search[:value]
      end

      def search_placeholder
        @search[:placeholder] || I18n.t('bali.filters.search_placeholder',
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

      # Translations JSON for Stimulus controllers (combinators only for main controller)
      def translations_json
        {
          combinators: {
            and: I18n.t('bali.filters.combinators.and', default: 'AND'),
            or: I18n.t('bali.filters.combinators.or', default: 'OR')
          }
        }.to_json
      end

      # Extract non-filter query params from the URL to preserve them when submitting.
      # Returns an array of [name, value] pairs suitable for hidden_field_tag.
      def preserved_query_params
        query_string = URI.parse(url).query
        return [] if query_string.blank?

        params = Rack::Utils.parse_nested_query(query_string)
        flatten_params(params.except(*EXCLUDED_PARAMS))
      end

      # Render hidden fields for preserved params (call from template)
      def preserved_params_hidden_fields
        safe_join(
          preserved_query_params.map { |name, value| helpers.hidden_field_tag(name, value) }
        )
      end

      private

      # Recursively flatten nested params hash into [name, value] pairs.
      # e.g., {"sort" => {"column" => "name"}} becomes [["sort[column]", "name"]]
      def flatten_params(params, prefix = nil)
        params.flat_map do |key, value|
          field_name = prefix ? "#{prefix}[#{key}]" : key.to_s

          case value
          when Hash  then flatten_params(value, field_name)
          when Array then value.map { |v| ["#{field_name}[]", v] }
          else            [[field_name, value]]
          end
        end
      end

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
