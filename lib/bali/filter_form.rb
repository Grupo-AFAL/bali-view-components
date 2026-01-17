# frozen_string_literal: true

module Bali
  class FilterForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :scope, :storage_id, :context, :clear_filters, :groupings

    # Ransack attribute for receiving the sort parameters
    attribute :s

    def initialize(scope, params = {}, storage_id: nil, context: nil)
      @scope = scope
      @storage_id = storage_id
      @context = context

      q_params = params.fetch(:q, {})
      attributes = q_params.permit(permitted_attributes)
      @clear_filters = params.fetch(:clear_filters, false)

      # Store Ransack groupings (g) and combinator (m) for complex filters
      # These are used by AdvancedFilters for AND/OR condition groups
      @groupings = extract_groupings(q_params)
      @combinator = q_params[:m]

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

    # Build params hash for Ransack including groupings if present
    def ransack_params
      params = query_params.dup

      # Add groupings for AdvancedFilters complex conditions
      params[:g] = @groupings if @groupings.present?
      params[:m] = @combinator if @combinator.present?

      params
    end

    # Extract Ransack groupings from params
    # Groupings format: q[g][0][field_operator]=value, q[g][0][m]=or/and
    def extract_groupings(q_params)
      return nil unless q_params[:g].present?

      # Convert ActionController::Parameters to a regular hash
      # Ransack expects groupings as a hash with string keys
      q_params[:g].to_unsafe_h
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
  end
end
