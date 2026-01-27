# frozen_string_literal: true

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

    attr_reader :scope, :storage_id, :context, :clear_filters, :groupings

    # Ransack attribute for receiving the sort parameters
    attribute :s

    class << self
      # Storage for filter attribute definitions used by Filters UI
      def filter_attributes
        @filter_attributes ||= []
      end

      # Storage for search field definitions used for quick text search
      def defined_search_fields
        @defined_search_fields ||= []
      end

      # Define quick search fields for text search across multiple columns.
      # This generates a Ransack predicate like "name_or_email_cont".
      #
      # @param fields [Array<Symbol>] Field names to search across
      #
      # @example
      #   search_fields :name, :email, :description
      #   # Generates: q[name_or_email_or_description_cont]
      def search_fields(*fields)
        @defined_search_fields = fields.flatten.map(&:to_sym)
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

      # Inherit filter_attributes and search_fields from parent class
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@filter_attributes, filter_attributes.dup)
        subclass.instance_variable_set(:@defined_search_fields, defined_search_fields.dup)
      end
    end

    # @param scope [ActiveRecord::Relation] The base scope to filter
    # @param params [Hash, ActionController::Parameters] Request params containing q[...]
    # @param storage_id [String] Optional cache key for persisting filters
    # @param context [String] Optional context for cache key namespacing
    # @param search_fields [Array<Symbol>] Fields for quick text search (alternative to DSL)
    # @param search_placeholder [String] Placeholder text for search input
    def initialize(scope, params = {}, storage_id: nil, context: nil, search_fields: nil,
                   search_placeholder: nil)
      @scope = scope
      @storage_id = storage_id
      @context = context
      @instance_search_fields = search_fields&.map(&:to_sym)
      @search_placeholder = search_placeholder

      q_params = params.fetch(:q, {})
      attributes = q_params.permit(permitted_attributes)
      @clear_filters = params.fetch(:clear_filters, false)

      # Store Ransack groupings (g) and combinator (m) for complex filters
      # These are used by Filters for AND/OR condition groups
      @groupings = extract_groupings(q_params)
      @combinator = q_params[:m]

      # Capture quick search value from params
      @search_value = extract_search_value(q_params)

      attributes = fetch_stored_attributes(attributes) if storage_id.present?
      super(attributes)
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

    def name
      @name ||= self.class.name.tableize
    end

    def cache_key
      @cache_key ||= "#{name};#{context};#{storage_id}"
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

    # Get the search fields for quick text search.
    # Prefers instance-level search_fields over class-level DSL.
    #
    # @return [Array<Symbol>] Field names to search across
    def search_fields
      @instance_search_fields.presence || self.class.defined_search_fields
    end

    # Check if quick search is enabled
    #
    # @return [Boolean]
    def search_enabled?
      search_fields.present?
    end

    # Get the current search value from params
    #
    # @return [String, nil]
    attr_reader :search_value

    # Get the placeholder text for search input
    #
    # @return [String]
    def search_placeholder
      @search_placeholder || I18n.t('bali.filters.search_placeholder', default: 'Search...')
    end

    # Build the Ransack field name for multi-field search.
    # e.g., [:name, :genre, :tenant_name] => "name_or_genre_or_tenant_name_cont"
    #
    # @return [String, nil]
    def search_field_name
      return nil unless search_enabled?

      "#{search_fields.map(&:to_s).join('_or_')}_cont"
    end

    # Get the full configuration hash for Filters component.
    # Used by DataTable to auto-configure the filters_panel.
    #
    # @return [Hash, nil] Search configuration or nil if not enabled
    def search_config
      return nil unless search_enabled?

      {
        fields: search_fields,
        value: search_value,
        placeholder: search_placeholder
      }
    end

    # Parse the current filter state into a structure for Filters component.
    # Automatically extracts filter groups from Ransack grouping params (q[g][...]).
    #
    # @return [Array<Hash>] Array of filter groups, each with :combinator and :conditions
    # @example Return structure
    #   [
    #     {
    #       combinator: 'or',
    #       conditions: [
    #         { attribute: 'name', operator: 'cont', value: 'john' },
    #         { attribute: 'status', operator: 'eq', value: 'active' }
    #       ]
    #     }
    #   ]
    def filter_groups
      return [] if @groupings.blank?

      @groupings.map do |_index, group_params|
        parse_filter_group(group_params.deep_symbolize_keys)
      end
    end

    # Get the top-level combinator that determines how filter groups are combined.
    #
    # @return [String] 'and' or 'or'
    def combinator
      @combinator || 'and'
    end

    # Get detailed information about each active filter condition.
    # Useful for displaying filter pills/tags with human-readable labels.
    #
    # @return [Array<Hash>] Array of filter details with metadata
    def active_filter_details
      details = []
      filter_groups.each_with_index do |group, group_idx|
        group[:conditions].each_with_index do |condition, condition_idx|
          next if condition[:value].blank?

          attr_config = available_attributes.find { |a| a[:key].to_s == condition[:attribute].to_s }

          details << {
            group_index: group_idx,
            condition_index: condition_idx,
            attribute: condition[:attribute],
            attribute_label: attr_config&.dig(:label) || condition[:attribute].to_s.humanize,
            operator: condition[:operator],
            value: condition[:value],
            value_label: format_filter_value(condition[:value], attr_config)
          }
        end
      end
      details
    end

    def non_date_range_attribute_names
      attribute_names - date_range_attributes
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

    private

    # Build params hash for Ransack including groupings and search
    def ransack_params
      params = query_params.dup

      # Add groupings for Filters complex conditions
      params[:g] = @groupings if @groupings.present?
      params[:m] = @combinator if @combinator.present?

      # Add quick search parameter
      params[search_field_name] = @search_value if search_enabled? && @search_value.present?

      params
    end

    # Extract Ransack groupings from params
    # Groupings format: q[g][0][field_operator]=value, q[g][0][m]=or/and
    def extract_groupings(q_params)
      return nil if q_params[:g].blank?

      # Convert ActionController::Parameters to a regular hash
      # Ransack expects groupings as a hash with string keys
      q_params[:g].to_unsafe_h
    end

    # Extract quick search value from params based on configured search_fields
    # Looks for q[name_or_genre_or_tenant_name_cont] based on search_fields config
    def extract_search_value(q_params)
      return nil unless search_enabled?

      q_params[search_field_name] || q_params[search_field_name.to_sym]
    end

    def fetch_stored_attributes(attributes)
      return attributes unless Object.const_defined?('Rails')

      if attributes.present?
        Rails.cache.write(cache_key, attributes)
      elsif @clear_filters
        Rails.cache.delete(cache_key)
        attributes = {}
      else
        attributes = Rails.cache.fetch(cache_key) || {}
      end

      attributes
    end

    def array_predicates
      %w[_any _all _not_in _in]
    end

    # Parse a single filter group from Ransack params into component structure.
    # Consolidates gteq/lteq pairs into 'between' operator for better UX.
    def parse_filter_group(group_params)
      raw_conditions = {}

      group_params.each do |key, value|
        next if key == :m # Skip combinator

        attr, operator = parse_condition_key(key.to_s)
        next unless attr

        raw_conditions[attr] ||= {}
        raw_conditions[attr][operator] = value
      end

      # Convert raw conditions, consolidating gteq+lteq into 'between'
      conditions = raw_conditions.flat_map do |attribute, ops|
        if ops['gteq'] && ops['lteq']
          # Combine into a single 'between' condition for date ranges
          [{
            attribute: attribute,
            operator: 'between',
            value: { start: ops['gteq'], end: ops['lteq'] }
          }]
        else
          ops.map do |operator, value|
            { attribute: attribute, operator: operator, value: value }
          end
        end
      end

      {
        combinator: group_params[:m] || 'or',
        conditions: conditions.presence || [default_filter_condition]
      }
    end

    # Parse a Ransack condition key like "name_cont" or "created_at_gteq"
    # into [attribute, operator] pair.
    def parse_condition_key(key)
      # Ordered by specificity (longer operators first to avoid partial matches)
      operators = %w[not_cont not_eq not_in gteq lteq cont start end matches eq gt lt in]

      operators.each do |op|
        if key.end_with?("_#{op}")
          attr = key.sub(/_#{op}$/, '')
          return [attr, op]
        end
      end

      nil
    end

    # Default empty condition for new filter groups
    def default_filter_condition
      { attribute: '', operator: 'cont', value: '' }
    end

    # Format a filter value for display, resolving select option labels
    def format_filter_value(value, attr_config)
      return value if attr_config.nil?
      return value unless attr_config[:type]&.to_sym == :select

      option = attr_config[:options]&.find do |opt|
        opt_value = opt.is_a?(Array) ? opt[1] : opt
        opt_value.to_s == value.to_s
      end

      option.is_a?(Array) ? option[0] : (option || value)
    end
  end
end
