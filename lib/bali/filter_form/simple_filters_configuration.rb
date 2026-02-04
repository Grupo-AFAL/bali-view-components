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
        #   or a Proc that returns such an array
        # @param blank [String, nil] Blank option text (e.g., "All Statuses")
        # @param label [String, nil] Human-readable label (defaults to humanized attribute)
        # @param default [String, nil] Default value when no filter is active
        #
        # @example Static collection
        #   simple_filter :status,
        #     collection: [["Active", "active"], ["Inactive", "inactive"]],
        #     blank: "All"
        #
        # @example Dynamic collection (evaluated at render time)
        #   simple_filter :legal_entity_id,
        #     collection: -> { LegalEntity.active.pluck(:name, :id) },
        #     blank: "All Entities",
        #     label: "Legal Entity"
        def simple_filter(attribute, collection:, blank: nil, label: nil, default: nil)
          defined_simple_filters << {
            attribute: attribute.to_sym,
            collection: collection,
            blank: blank,
            label: label,
            default: default
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
          {
            attribute: filter[:attribute],
            collection: resolve_collection(filter[:collection]),
            blank: filter[:blank],
            label: filter[:label] || infer_simple_filter_label(filter[:attribute]),
            default: filter[:default],
            value: current_simple_filter_value(filter[:attribute])
          }
        end
      end

      # Check if any simple filter has an active value
      #
      # @return [Boolean]
      def simple_filters_active?
        simple_filters.any? { |f| current_simple_filter_value(f[:attribute]).present? }
      end

      private

      # Add simple filter values to Ransack params
      # Called from FilterForm#ransack_params
      def add_simple_filter_params(params)
        simple_filters.each do |filter|
          value = current_simple_filter_value(filter[:attribute])
          next if value.blank?

          params["#{filter[:attribute]}_eq"] = value
        end
      end

      # Get current value for a simple filter from params
      # Simple filters use _eq predicate (equality match)
      def current_simple_filter_value(attribute)
        return nil unless defined?(@q_params) && @q_params.present?

        @q_params["#{attribute}_eq"] || @q_params[:"#{attribute}_eq"]
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
