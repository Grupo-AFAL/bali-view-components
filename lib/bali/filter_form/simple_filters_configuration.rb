# frozen_string_literal: true

module Bali
  class FilterForm
    # SimpleFiltersConfiguration provides DSL and methods for simple inline dropdown filters.
    # Unlike the complex Filters component, simple filters render as inline select dropdowns
    # without AND/OR groupings, operators, or popovers.
    #
    # @example Class-level DSL
    #   class DepartmentsFilterForm < Bali::FilterForm
    #     simple_filter :legal_entity_id,
    #       collection: -> { LegalEntity.active.pluck(:name, :id) },
    #       blank: "All Entities"
    #
    #     simple_filter :status,
    #       collection: [["Active", "active"], ["Inactive", "inactive"]],
    #       blank: "All",
    #       default: "active"
    #   end
    #
    # @example Instance-level configuration
    #   FilterForm.new(Department.all, params, simple_filters: [
    #     { attribute: :status, collection: [...], blank: "All" }
    #   ])
    #
    module SimpleFiltersConfiguration
      extend ActiveSupport::Concern

      class_methods do
        # Storage for simple filter definitions
        def defined_simple_filters
          @defined_simple_filters ||= []
        end

        # Define a simple dropdown filter for the SimpleFilters component.
        #
        # @param attribute [Symbol] Attribute key (column name)
        # @param collection [Array, Proc] Options for select - array of [label, value] pairs
        #   or a Proc that returns such an array (not needed for :date type)
        # @param blank [String, nil] Blank option text (e.g., "All Statuses")
        # @param label [String, nil] Human-readable label (defaults to humanized attribute)
        # @param default [String, nil] Default value when no filter is active
        # @param icon [String, nil] Icon name to display
        # @param type [Symbol] Filter input type (:select, :slim_select, :date, :date_range, :toggle_group)
        # @param predicate [Symbol] Ransack predicate (default: :eq)
        #
        # @example Static collection
        #   simple_filter :status,
        #     collection: [["Active", "active"], ["Inactive", "inactive"]],
        #     blank: "All"
        #
        # @example Searchable dropdown
        #   simple_filter :country,
        #     collection: Country.pluck(:name, :code),
        #     blank: "All Countries",
        #     type: :slim_select
        #
        # @example Date filter
        #   simple_filter :created_at,
        #     type: :date,
        #     predicate: :gteq,
        #     label: "Created after"
        def simple_filter(attribute, collection: nil, blank: nil, label: nil, default: nil,
                          type: :select, predicate: :eq, icon: nil)
          defined_simple_filters << {
            attribute: attribute.to_sym,
            collection: collection,
            blank: blank,
            label: label,
            default: default,
            type: type.to_sym,
            predicate: predicate.to_sym,
            icon: icon
          }
        end

        # Inherit simple_filters from parent class
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@defined_simple_filters, defined_simple_filters.dup)
        end
      end

      # Get the simple filters configuration.
      # Prefers instance-level simple_filters over class-level DSL.
      #
      # @return [Array<Hash>] Array of filter definitions
      def simple_filters
        @instance_simple_filters.presence || self.class.defined_simple_filters
      end

      # Check if simple filters are enabled
      #
      # @return [Boolean]
      def simple_filters_enabled?
        simple_filters.present?
      end

      # Get the full configuration for SimpleFilters component.
      # Resolves callable collections and adds current values.
      #
      # @return [Array<Hash>, nil] Filter configurations or nil if not enabled
      def simple_filters_config
        return nil unless simple_filters_enabled?

        simple_filters.map do |filter|
          type, predicate = resolve_filter_type_and_predicate(filter)

          config = {
            attribute: filter[:attribute],
            collection: resolve_collection(filter[:collection]),
            blank: filter[:blank],
            label: filter[:label] || infer_simple_filter_label(filter[:attribute]),
            default: filter[:default],
            type: type,
            predicate: predicate,
            icon: filter[:icon],
            value: current_simple_filter_value(filter[:attribute], predicate)
          }

          if type == :number_range
            config[:value] = current_number_range_value(filter[:attribute])
            config[:step] = filter[:step]
            config[:placeholder_min] = filter[:placeholder_min]
            config[:placeholder_max] = filter[:placeholder_max]
          end

          config
        end
      end

      # Check if any simple filter has an active value
      #
      # @return [Boolean]
      def simple_filters_active?
        simple_filters.any? do |f|
          type, predicate = resolve_filter_type_and_predicate(f)
          if type == :number_range
            value = current_number_range_value(f[:attribute])
            value[:min].present? || value[:max].present?
          else
            current_simple_filter_value(f[:attribute], predicate).present?
          end
        end
      end

      def simple_date_range_attributes
        return [] unless simple_filters_enabled?

        simple_filters.select { |f| resolve_filter_type_and_predicate(f).first == :date_range }
                      .map { |f| f[:attribute].to_sym }
      end

      def simple_filters_permitted_keys
        return [] unless simple_filters_enabled?

        keys = []
        simple_filters.each do |filter|
          type, predicate = resolve_filter_type_and_predicate(filter)
          key = predicate.present? ? "#{filter[:attribute]}_#{predicate}" : filter[:attribute].to_s

          if type == :toggle_group
            keys << { key => [] }
          elsif type == :number_range
            keys << "#{filter[:attribute]}_gteq"
            keys << "#{filter[:attribute]}_lteq"
          else
            keys << key
          end
        end
        keys
      end

      private

      # Resolve type and predicate from a filter hash, normalizing to symbols.
      # Date range filters have no predicate (handled via where clause).
      def resolve_filter_type_and_predicate(filter)
        type = filter[:type]&.to_sym || :select
        predicate = filter[:predicate] || (type == :date_range ? nil : :eq)
        [ type, predicate ]
      end

      # Add simple filter values to Ransack params
      # Called from FilterForm#ransack_params
      def add_simple_filter_params(params)
        simple_filters.each do |filter|
          type, predicate = resolve_filter_type_and_predicate(filter)
          next if type == :date_range # Handled separately via where clause

          if type == :number_range
            values = current_number_range_value(filter[:attribute])
            params["#{filter[:attribute]}_gteq"] = values[:min] if values[:min].present?
            params["#{filter[:attribute]}_lteq"] = values[:max] if values[:max].present?
          else
            value = current_simple_filter_value(filter[:attribute], predicate)
            next if value.blank?

            params["#{filter[:attribute]}_#{predicate}"] = value
          end
        end
      end

      # Get current value for a simple filter from params
      def current_simple_filter_value(attribute, predicate = :eq)
        key = predicate.present? ? "#{attribute}_#{predicate}" : attribute.to_s

        # 1. Try raw params first (for non-persisted immediate feedback)
        value = nil
        value = @q_params[key] || @q_params[key.to_sym] if defined?(@q_params) && @q_params.present?

        # 2. Try instance attribute (for persisted/restored values)
        value ||= send(key) if respond_to?(key)

        if value.is_a?(Array)
          return value.compact_blank
        end

        value
      end

      # Get current min/max values for a number_range filter from params
      def current_number_range_value(attribute)
        {
          min: current_simple_filter_value(attribute, :gteq),
          max: current_simple_filter_value(attribute, :lteq)
        }
      end

      # Resolve collection - call if Proc, return as-is otherwise
      def resolve_collection(collection)
        collection.respond_to?(:call) ? collection.call : collection
      end

      # Infer label from attribute name using I18n or humanization
      def infer_simple_filter_label(attribute)
        # Try model-specific I18n first
        if respond_to?(:scope) && scope.respond_to?(:model)
          model_name = scope.model.model_name.i18n_key
          i18n_key = "activerecord.attributes.#{model_name}.#{attribute}"
          translated = I18n.t(i18n_key, default: nil)
          return translated if translated
        end

        # Fallback to humanized attribute name
        attribute.to_s.humanize
      end
    end
  end
end
