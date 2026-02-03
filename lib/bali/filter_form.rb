# frozen_string_literal: true

require_relative 'filter_form/search_configuration'
require_relative 'filter_form/filter_group_parser'
require_relative 'filter_form/simple_filters_configuration'

module Bali
  # FilterForm provides a unified interface for Ransack-based filtering with support
  # for both simple filters and complex AND/OR grouped conditions.
  #
  # @example Basic usage with attribute DSL
  #   class UsersFilterForm < Bali::FilterForm
  #     # Declare quick search fields (searches across multiple columns)
  #     search_fields :name, :email
  #
  #     # Declare filterable attributes for Filters UI
  #     filter_attribute :name, type: :text
  #     filter_attribute :email, type: :text
  #     filter_attribute :status, type: :select,
  #                      options: [['Active', 'active'], ['Inactive', 'inactive']]
  #     filter_attribute :created_at, type: :date
  #
  #     # Standard Ransack attributes for simple filtering
  #     attribute :name_cont
  #     attribute :status_eq
  #   end
  #
  #   # In controller
  #   @filter_form = UsersFilterForm.new(User.all, params, storage_id: 'users')
  #   @users = @filter_form.result
  #
  #   # In view - everything auto-configured from FilterForm
  #   data_table.with_filters_panel
  #
  # @example Using search_fields without subclassing
  #   @filter_form = Bali::FilterForm.new(
  #     Movie.all,
  #     params,
  #     search_fields: [:name, :genre, :tenant_name]
  #   )
  #
  class FilterForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include SearchConfiguration
    include FilterGroupParser
    include SimpleFiltersConfiguration

    attr_reader :scope, :storage_id, :context, :clear_filters, :groupings

    # Ransack attribute for receiving the sort parameters
    attribute :s

    class << self
      # Storage for filter attribute definitions used by Filters UI
      def filter_attributes
        @filter_attributes ||= []
      end

      # Define a filterable attribute for the Filters component.
      # This is used to generate the filter UI and provide labels/options.
      #
      # @param key [Symbol] Attribute key (column name or Ransack association path)
      # @param type [Symbol] Attribute type: :text, :number, :date, :datetime,
      #   :select, :boolean
      # @param label [String] Human-readable label (defaults to humanized key)
      # @param options [Array] For select types, array of [label, value] pairs
      #
      # @example
      #   filter_attribute :name, type: :text
      #   filter_attribute :status, type: :select,
      #     options: [['Active', 'active'], ['Inactive', 'inactive']]
      #   filter_attribute :created_at, type: :date, label: 'Created Date'
      def filter_attribute(key, type: :text, label: nil, options: [])
        filter_attributes << {
          key: key,
          type: type,
          label: label || key.to_s.humanize,
          options: options
        }
      end

      # Inherit filter_attributes from parent class
      # Note: search_fields inheritance is handled by SearchConfiguration concern
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@filter_attributes, filter_attributes.dup)
      end
    end

    # @param scope [ActiveRecord::Relation] The base scope to filter
    # @param params [Hash, ActionController::Parameters] Request params containing q[...]
    # @param storage_id [String] Optional cache key for persisting filters
    # @param context [String] Optional context for cache key namespacing
    # @param search_fields [Array<Symbol>] Fields for quick text search (alternative to DSL)
    # @param search_placeholder [String] Placeholder text for search input
    # @param persist_enabled [Boolean] Whether user has opted into filter persistence
    #   (default: false). When false, filters are saved but not restored.
    # @param simple_filters [Array<Hash>] Simple inline filters (alternative to DSL)
    # rubocop:disable Metrics/ParameterLists
    def initialize(scope, params = {}, storage_id: nil, context: nil, search_fields: nil,
                   search_placeholder: nil, persist_enabled: false, simple_filters: nil)
      # rubocop:enable Metrics/ParameterLists
      @scope = scope
      @storage_id = storage_id
      @context = context
      @instance_search_fields = search_fields&.map(&:to_sym)
      @instance_simple_filters = simple_filters
      @search_placeholder = search_placeholder
      @persist_enabled = persist_enabled
      @clear_filters = params.fetch(:clear_filters, false)
      @clear_search = params.fetch(:clear_search, false)

      q_params = params.fetch(:q, {})
      @q_params = q_params # Store for simple_filters value extraction
      attributes = q_params.permit(permitted_attributes)

      # Extract Ransack groupings (g) and combinator (m) for complex filters
      # These are used by Filters for AND/OR condition groups
      @groupings = extract_groupings(q_params)
      @combinator = q_params[:m]

      # Capture quick search value from params
      @search_value = extract_search_value(q_params)

      # Persist/restore all filter state (attributes, groupings, combinator, search)
      if storage_id.present?
        attributes, @groupings, @combinator, @search_value = fetch_stored_filter_state(
          attributes, @groupings, @combinator, @search_value
        )
      end

      super(attributes)
    end

    # Check if user has opted into filter persistence
    def persist_enabled?
      @persist_enabled
    end

    def permitted_attributes
      scalar_attributes + date_range_attributes + array_attributes.map { |a| { a => [] } }
    end

    # To define array attributes the user needs to specify an array as
    # it's default value.
    #
    # e.g.
    # attribute :vendors_id_in, default: []
    #
    def array_attributes
      @array_attributes ||= self.class.attribute_names.select do |attribute_name|
        array_predicates.any? { |predicate| attribute_name.ends_with?(predicate) }
      end
    end

    def scalar_attributes
      @scalar_attributes ||= self.class._default_attributes.keys - non_scalar_attributes
    end

    def non_scalar_attributes
      @non_scalar_attributes ||= array_attributes + date_range_attributes
    end

    def date_range_attributes
      @date_range_attributes ||= self.class.attribute_names.filter do |key|
        self.class.attribute_types[key].instance_of?(Bali::Types::DateRangeValue)
      end
    end

    def model_name
      @model_name ||= ActiveModel::Name.new(self, nil, 'q')
    end

    def inspect
      "<#{self.class.name} attributes=[#{attribute_names.join(',')}]>"
    end

    def id
      @id ||= scope.cache_key
    end

    def cache_key
      @cache_key ||= "#{self.class.name.tableize};#{context};#{storage_id}"
    end

    def active_filters_count
      (active_filters.keys & attribute_names).size
    end

    def active_filters?
      active_filters.any?
    end

    def active_filters
      @active_filters || query_params.except('s').compact_blank
    end

    # Get the available filter attributes defined via filter_attribute DSL.
    # Used by Filters component for rendering the filter UI.
    #
    # @return [Array<Hash>] Array of attribute definitions with :key, :type, :label, :options
    def available_attributes
      self.class.filter_attributes
    end

    def query_params
      @query_params ||= non_date_range_attribute_names.index_with do |attr_name|
        (value = send(attr_name.to_sym)).is_a?(Array) ? value.compact_blank.presence : value
      end
    end

    def result(options = {})
      @result ||= begin
        relation = ransack_search.result(**options)

        date_range_attributes.each do |date_range_attr|
          next if send(date_range_attr).blank?

          relation = relation.where(date_range_attr => send(date_range_attr))
        end

        relation
      end
    end

    def ransack_search
      @ransack_search ||= scope.ransack(ransack_params)
    end

    # Build params hash for Ransack including groupings and search
    def ransack_params
      params = query_params.dup

      # Add groupings for Filters complex conditions
      params[:g] = @groupings if @groupings.present?
      params[:m] = @combinator if @combinator.present?

      # Add quick search parameter
      params[search_field_name] = @search_value if search_enabled? && @search_value.present?

      # Add simple filter parameters
      add_simple_filter_params(params) if simple_filters_enabled?

      params
    end

    private

    def non_date_range_attribute_names
      attribute_names - date_range_attributes
    end

    # Extract Ransack groupings from params
    # Groupings format: q[g][0][field_operator]=value, q[g][0][m]=or/and
    def extract_groupings(q_params)
      return nil if q_params[:g].blank?

      # Convert ActionController::Parameters to a regular hash
      # Ransack expects groupings as a hash with string keys
      q_params[:g].to_unsafe_h
    end

    # Persist or restore complete filter state including groupings, combinator, and search.
    # Returns [attributes, groupings, combinator, search_value] tuple.
    #
    # Behavior depends on @persist_enabled:
    # - Always saves filters when user submits new ones (so they're available if user enables later)
    # - Only restores filters when @persist_enabled is true
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def fetch_stored_filter_state(attributes, groupings, combinator, search_value)
      return [attributes, groupings, combinator, search_value] unless Object.const_defined?('Rails')

      has_filter_params = attributes.present? || groupings.present? || search_value.present?

      if has_filter_params
        # User submitted new filters → always save complete state
        Rails.cache.write(cache_key, {
                            attributes: attributes.to_h,
                            groupings: groupings,
                            combinator: combinator,
                            search_value: search_value
                          })
        [attributes, groupings, combinator, search_value]
      elsif @clear_filters
        # User clicked "Clear all" → delete stored filters
        Rails.cache.delete(cache_key)
        [{}, nil, nil, nil]
      elsif @clear_search
        # User clicked search clear button → clear just the search from storage
        stored = Rails.cache.fetch(cache_key)
        if stored.is_a?(Hash)
          Rails.cache.write(cache_key, stored.merge(search_value: nil))
          [stored[:attributes] || {}, stored[:groupings], stored[:combinator], nil]
        else
          [{}, nil, nil, nil]
        end
      elsif @persist_enabled
        # No filters in URL and persistence enabled → restore from cache
        stored = Rails.cache.fetch(cache_key)
        if stored.is_a?(Hash) && stored[:attributes]
          [
            stored[:attributes] || {},
            stored[:groupings],
            stored[:combinator],
            stored[:search_value]
          ]
        else
          # Legacy format (just attributes) or empty
          [stored || {}, nil, nil, nil]
        end
      else
        # Persistence not enabled → don't restore, return empty
        [{}, nil, nil, nil]
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def array_predicates
      %w[_any _all _not_in _in]
    end
  end
end
