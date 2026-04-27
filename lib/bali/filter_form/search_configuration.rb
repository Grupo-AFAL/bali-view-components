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

        def defined_search_icon
          @defined_search_icon
        end

        # Define quick search fields for text search across multiple columns.
        # This generates a Ransack predicate like "name_or_email_cont".
        #
        # @param fields [Array<Symbol>] Field names to search across
        # @param icon [String, nil] Icon name for search input
        #
        # @example
        #   search_fields :name, :email, icon: 'search'
        def search_fields(*fields, icon: nil)
          @defined_search_icon = icon
          @defined_search_fields = fields.flatten.map(&:to_sym)
        end

        # Inherit search_fields from parent class
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@defined_search_fields, defined_search_fields.dup)
          subclass.instance_variable_set(:@defined_search_icon, defined_search_icon)
        end
      end

      # Get the search fields for quick text search.
      # Prefers instance-level search_fields over class-level DSL.
      #
      # @return [Array<Symbol>] Field names to search across
      def search_fields
        @instance_search_fields.presence || self.class.defined_search_fields
      end

      # Get the search icon name.
      def search_icon
        @instance_search_icon || self.class.defined_search_icon
      end

      # Check if quick search is enabled
      #
      # @return [Boolean]
      def search_enabled?
        search_fields.present?
      end

      # Get the placeholder text for search input.
      # Auto-generates from field names if no custom placeholder is set.
      # e.g., search_fields [:name, :email] => "Search by name, email..."
      #
      # @return [String]
      def search_placeholder
        @search_placeholder || default_search_placeholder
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

      # Get the search configuration hash for SimpleFilters component.
      # Returns a hash compatible with SimpleFilters::Component's search parameter.
      #
      # @return [Hash, nil] Search configuration or nil if not enabled
      def simple_search_config
        return nil unless search_enabled?

        {
          field_name: "q[#{search_field_name}]",
          value: search_value,
          placeholder: search_placeholder,
          icon: search_icon
        }
      end

      private

      # Generate a descriptive placeholder from search field names.
      # e.g., [:name] => "Search by name..."
      # e.g., [:name, :email] => "Search by name, email..."
      #
      # Field names go through `human_attribute_name` when the scope exposes a
      # model class, so consumers' existing `activerecord.attributes.*`
      # translations come through automatically.
      def default_search_placeholder
        unless search_enabled?
          return I18n.t("bali.filters.search_placeholder", default: "Search...")
        end

        I18n.t(
          "bali.filter_form.search_placeholder_with_fields",
          fields: search_field_labels.join(", "),
          default: "Search by %{fields}..."
        )
      end

      def search_field_labels
        search_fields.map { |f| search_field_label(f) }
      end

      def search_field_label(field)
        @scope.model.human_attribute_name(field).downcase
      rescue NoMethodError
        field.to_s.humanize(capitalize: false)
      end

      # Extract quick search value from params based on configured search_fields
      # Looks for q[name_or_genre_or_tenant_name_cont] based on search_fields config
      def extract_search_value(q_params)
        return nil unless search_enabled?

        q_params[search_field_name] || q_params[search_field_name.to_sym]
      end
    end
  end
end
