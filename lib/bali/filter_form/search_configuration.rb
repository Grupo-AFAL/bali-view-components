# frozen_string_literal: true

module Bali
  class FilterForm
    # SearchConfiguration provides DSL and methods for quick text search
    # across multiple columns using Ransack predicates.
    #
    # @example Class-level DSL
    #   class UsersFilterForm < Bali::FilterForm
    #     search_fields :name, :email, :description
    #   end
    #   # Generates: q[name_or_email_or_description_cont]
    #
    # @example Instance-level configuration
    #   FilterForm.new(User.all, params, search_fields: [:name, :email])
    #
    module SearchConfiguration
      extend ActiveSupport::Concern

      included do
        attr_reader :search_value
      end

      class_methods do
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

        # Inherit search_fields from parent class
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@defined_search_fields, defined_search_fields.dup)
        end
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

      private

      # Extract quick search value from params based on configured search_fields
      # Looks for q[name_or_genre_or_tenant_name_cont] based on search_fields config
      def extract_search_value(q_params)
        return nil unless search_enabled?

        q_params[search_field_name] || q_params[search_field_name.to_sym]
      end
    end
  end
end
