# frozen_string_literal: true

module Bali
  class FilterForm
    # SimpleFiltersConfiguration provides DSL and methods for simple inline dropdown filters.
    # Unlike the complex Filters component, simple filters render as inline select dropdowns
    # without AND/OR groupings, operators, or popovers.
    #
    # @example Class-level DSL (canonical: unified filter_attribute)
    #   class DepartmentsFilterForm < Bali::FilterForm
    #     filter_attribute :legal_entity_id, type: :select, simple: true,
    #       options: -> { LegalEntity.where(id: scope.select(:legal_entity_id)).pluck(:name, :id) },
    #       blank: "All Entities"
    #
    #     # Legacy alias (still supported): simple-UI-only declaration
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
        # Data type (advanced Filters UI vocabulary) implied by each legacy
        # simple_filter widget type.
        LEGACY_TYPE_FOR_INPUT = {
          select: :select, slim_select: :select, toggle_group: :select, radio_group: :select,
          boolean: :boolean, date: :date, date_range: :date, number_range: :number
        }.freeze

        # Simple filter definitions, derived from the unified filter_attribute
        # storage (entries declared with `simple: true`) and mapped to the
        # legacy shape the SimpleFilters pipeline consumes.
        def defined_simple_filters
          filter_attributes.select { |attr| attr[:simple] }.map do |attr|
            {
              attribute: attr[:key],
              collection: attr[:options],
              blank: attr[:blank],
              label: attr[:explicit_label],
              default: attr[:default],
              type: attr[:input],
              # date_range filters have no single predicate (range handled via where clause)
              predicate: attr[:input] == :date_range ? nil : attr[:predicate],
              icon: attr[:icon],
              step: attr[:step],
              placeholder_min: attr[:placeholder_min],
              placeholder_max: attr[:placeholder_max]
            }
          end
        end

        # Define a simple dropdown filter for the SimpleFilters component.
        #
        # @deprecated Legacy alias for {Bali::FilterForm.filter_attribute} with
        #   `simple: true, advanced: false`. Kept for backwards compatibility;
        #   new code should declare a single filter_attribute per attribute so
        #   both filter UIs share one definition.
        #
        # @param attribute [Symbol] Attribute key (column name)
        # @param collection [Array, Proc] Options for select - array of [label, value] pairs
        #   or a Proc that returns such an array (not needed for :date type).
        #   Zero-arity procs run with instance_exec, so they can use `scope`
        #   (the relation the controller passed in, typically policy-scoped).
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
        # @example Date filter
        #   simple_filter :created_at,
        #     type: :date,
        #     predicate: :gteq,
        #     label: "Created after"
        def simple_filter(attribute, collection: nil, blank: nil, label: nil, default: nil,
                          type: :select, predicate: :eq, icon: nil)
          input = type.to_sym
          filter_attribute(
            attribute,
            type: LEGACY_TYPE_FOR_INPUT.fetch(input, :select),
            label: label,
            options: collection,
            simple: true,
            advanced: false,
            input: input,
            predicate: predicate,
            blank: blank,
            default: default,
            icon: icon
          )
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
            blank: resolve_definition_value(filter[:blank]),
            label: resolve_definition_value(filter[:label]) || infer_simple_filter_label(filter[:attribute]),
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

      # Resolve collection — arrays pass through; zero-arity procs run with
      # instance_exec (see FilterForm#resolve_definition_value), so class-level
      # lambdas can build collections narrowed to the policy scope via `scope`.
      def resolve_collection(collection)
        resolve_definition_value(collection)
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
