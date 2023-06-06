# frozen_string_literal: true

module Bali
  class FilterForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :scope, :storage_id, :context, :clear_filters

    # Ransack attribute for receiving the sort parameters
    attribute :s

    def initialize(scope, params = {}, storage_id: nil, context: nil)
      @scope = scope
      @storage_id = storage_id
      @context = context
      attributes = params.fetch(:q, {}).permit(permitted_attributes)
      @clear_filters = params.fetch(:clear_filters, false)

      attributes = fetch_stored_attributes(attributes) if storage_id.present?
      super(attributes)
    end

    def permitted_attributes
      scalar_attributes + array_attributes.map { |a| { a => [] } }
    end

    # To define array attributes the user needs to specify an array as
    # it's default value.
    #
    # e.g.
    # attribute :vendors_id_in, default: []
    #
    def array_attributes
      @array_attributes ||= self.class._default_attributes.keys.filter do |key|
        default_value = self.class._default_attributes[key].value_before_type_cast
        default_value.is_a?(Array)
      end
    end

    def scalar_attributes
      @scalar_attributes ||= self.class._default_attributes.keys - array_attributes
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
      @active_filters || query_params.except('s').filter { |_k, v| v.present? }
    end

    def query_params
      @query_params ||= attribute_names.index_with do |attr_name|
        send(attr_name.to_sym)
      end
    end

    def result(options = {})
      @result ||= ransack_search.result(**options)
    end

    def ransack_search
      @ransack_search ||= scope.ransack(query_params)
    end

    private

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
  end
end
