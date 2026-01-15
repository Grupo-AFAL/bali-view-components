# frozen_string_literal: true

module Bali
  # AdvancedFilterForm handles complex filter queries with AND/OR groupings
  # compatible with Ransack's grouping feature.
  #
  # @example Basic usage
  #   class UsersFilterForm < Bali::AdvancedFilterForm
  #     # Define available attributes for filtering
  #     filter_attribute :name, type: :text
  #     filter_attribute :email, type: :text
  #     filter_attribute :status, type: :select,
  #                      options: [['Active', 'active'], ['Inactive', 'inactive']]
  #     filter_attribute :created_at, type: :date
  #     filter_attribute :age, type: :number
  #   end
  #
  #   # In controller
  #   @filter_form = UsersFilterForm.new(User.all, params)
  #   @users = @filter_form.result
  #
  class AdvancedFilterForm
    include ActiveModel::Model

    attr_reader :scope, :params, :clear_filters

    class << self
      def filter_attributes
        @filter_attributes ||= []
      end

      # Define a filterable attribute
      #
      # @param key [Symbol] The attribute key (column name)
      # @param type [Symbol] The attribute type
      #   (:text, :number, :date, :datetime, :select, :boolean)
      # @param label [String] Human-readable label (defaults to humanized key)
      # @param options [Array] For select types, the available options
      def filter_attribute(key, type: :text, label: nil, options: [])
        filter_attributes << {
          key: key,
          type: type,
          label: label || key.to_s.humanize,
          options: options
        }
      end
    end

    def initialize(scope, params = {})
      @scope = scope
      @params = params
      @clear_filters = params.fetch(:clear_filters, false)
      @query_params = parse_params(params.fetch(:q, {}))
    end

    # Get the available filter attributes
    def available_attributes
      self.class.filter_attributes
    end

    # Parse the current filter state into a structure for the component
    def filter_groups
      return [default_group] if @query_params[:g].blank?

      @query_params[:g].map do |_index, group_params|
        parse_group(group_params)
      end
    end

    # Get the top-level combinator (how groups are combined)
    def combinator
      @query_params[:m] || 'and'
    end

    # Execute the query and return results
    def result(options = {})
      @result ||= begin
        search = scope.ransack(build_ransack_params)
        search.result(**options)
      end
    end

    # Build Ransack-compatible params from the parsed structure
    def build_ransack_params
      ransack_params = {}

      if @query_params[:g].present?
        ransack_params[:g] = {}
        @query_params[:g].each do |index, group|
          ransack_params[:g][index] = build_group_params(group)
        end
        ransack_params[:m] = @query_params[:m] || 'and'
      end

      # Also include any direct (non-grouped) params
      @query_params.except(:g, :m).each do |key, value|
        ransack_params[key] = value if value.present?
      end

      ransack_params
    end

    # Check if any filters are active
    def active_filters?
      active_filters_count.positive?
    end

    # Count active filters
    def active_filters_count
      count = 0
      filter_groups.each do |group|
        group[:conditions].each do |condition|
          count += 1 if condition[:value].present?
        end
      end
      count
    end

    # Get a list of active filter details (for displaying pills)
    def active_filter_details
      details = []
      filter_groups.each_with_index do |group, group_idx|
        group[:conditions].each_with_index do |condition, condition_idx|
          next if condition[:value].blank?

          attr_config = available_attributes.find { |a| a[:key].to_s == condition[:attribute].to_s }
          next unless attr_config

          details << {
            group_index: group_idx,
            condition_index: condition_idx,
            attribute: condition[:attribute],
            attribute_label: attr_config[:label],
            operator: condition[:operator],
            value: condition[:value],
            value_label: format_value(condition[:value], attr_config)
          }
        end
      end
      details
    end

    private

    def parse_params(params)
      return {} if params.blank?

      params.to_h.deep_symbolize_keys
    end

    def parse_group(group_params)
      conditions = []

      group_params.each do |key, value|
        next if key == :m # combinator

        # Parse condition from key like "status_eq" or "name_cont"
        attr, operator = parse_condition_key(key.to_s)
        next unless attr

        conditions << {
          attribute: attr,
          operator: operator,
          value: value
        }
      end

      {
        combinator: group_params[:m] || 'or',
        conditions: conditions.presence || [default_condition]
      }
    end

    def parse_condition_key(key)
      # Match patterns like "name_cont", "status_eq", "created_at_gteq"
      operators = %w[eq not_eq cont not_cont start end gt lt gteq lteq in not_in matches]

      operators.each do |op|
        if key.end_with?("_#{op}")
          attr = key.sub(/_#{op}$/, '')
          return [attr, op]
        end
      end

      nil
    end

    def build_group_params(group)
      params = { m: group[:m] || 'or' }

      group.except(:m).each do |key, value|
        params[key] = value if value.present?
      end

      params
    end

    def default_group
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

    def format_value(value, attr_config)
      return value unless attr_config[:type].to_sym == :select

      option = attr_config[:options].find do |opt|
        opt_value = opt.is_a?(Array) ? opt[1] : opt
        opt_value.to_s == value.to_s
      end

      option.is_a?(Array) ? option[0] : (option || value)
    end
  end
end
