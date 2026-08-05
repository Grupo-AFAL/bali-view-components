# frozen_string_literal: true

module Bali
  class FilterForm
    # SimpleFiltersConfiguration provides DSL and methods for simple inline dropdown filters.
    # Unlike the complex Filters component, simple filters render as inline select dropdowns
    # without AND/OR groupings, operators, or popovers.
    #
    # @example Class-level DSL (unified filter_attribute)
    #   class DepartmentsFilterForm < Bali::FilterForm
    #     filter_attribute :legal_entity_id, type: :select, simple: true,
    #       options: -> { LegalEntity.where(id: scope.select(:legal_entity_id)).pluck(:name, :id) },
    #       blank: "All Entities"
    #
    #     # Simple UI only (the advanced popover skips it)
    #     filter_attribute :status, type: :select, simple: true, advanced: false,
    #       options: [["Active", "active"], ["Inactive", "inactive"]],
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
        # Data type (advanced Filters UI vocabulary) implied by each deprecated
        # simple_filter widget type.
        LEGACY_TYPE_FOR_INPUT = {
          select: :select, slim_select: :select, toggle_group: :select, radio_group: :select,
          boolean: :boolean, date: :date, date_range: :date, number_range: :number
        }.freeze

        # Simple filter definitions, derived from the unified filter_attribute
        # storage (entries declared with `simple: true`) and mapped to the
        # shape the SimpleFilters pipeline consumes.
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
        # @deprecated Removed in Bali 4.0. Use {Bali::FilterForm.filter_attribute}
        #   with `simple: true, advanced: false` so one declaration feeds both
        #   filter UIs. `collection:` becomes `options:` and `type:` becomes
        #   `input:` (the data `type:` is inferred by the table below).
        def simple_filter(attribute, collection: nil, blank: nil, label: nil, default: nil,
                          type: :select, predicate: :eq, icon: nil)
          input = type.to_sym
          data_type = LEGACY_TYPE_FOR_INPUT.fetch(input, :select)

          Bali.deprecator.warn(
            "FilterForm.simple_filter is deprecated. Declare it as " \
            "`filter_attribute :#{attribute}, type: :#{data_type}, input: :#{input}, " \
            "simple: true, advanced: false` (collection: becomes options:) so the same " \
            "definition can also feed the advanced Filters popover."
          )

          filter_attribute(
            attribute,
            type: data_type,
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
            label: simple_filter_label(filter),
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

      # The simple filters that are narrowing the listing right now, keyed the way
      # the query carries them (`country_eq`, `founded_year_gteq`, …).
      #
      # This is the state model for the whole simple-filters surface, and it is the
      # single place that knows how a definition turns into a key/value pair. The
      # value of a simple filter never becomes an ActiveModel attribute — it lives
      # in `@q_params` and goes straight to Ransack — so anything that wants to ask
      # "what is set?" has to come through here rather than through `attributes`.
      #
      # @param include_date_ranges [Boolean] date ranges are applied with a `where`
      #   clause rather than a Ransack predicate, so the Ransack params builder asks
      #   for them to be left out. Every other caller wants them: a date range that
      #   is cutting the result is an active filter like any other.
      # @return [Hash{String => Object}]
      def active_simple_filters(include_date_ranges: true)
        return {} unless simple_filters_enabled?

        simple_filters.each_with_object({}) do |filter, active|
          type, predicate = resolve_filter_type_and_predicate(filter)
          next if type == :date_range && !include_date_ranges

          if type == :number_range
            min, max = current_number_range_value(filter[:attribute]).values_at(:min, :max)
            active["#{filter[:attribute]}_gteq"] = min if min.present?
            active["#{filter[:attribute]}_lteq"] = max if max.present?
          else
            value = current_simple_filter_value(filter[:attribute], predicate)
            next if value.blank?

            active[simple_filter_key(filter[:attribute], predicate)] = value
          end
        end
      end

      # Check if any simple filter has an active value
      #
      # @return [Boolean]
      def simple_filters_active?
        active_simple_filters.any?
      end

      # Whether the request carried a simple filter FIELD, with or without a value.
      #
      # This is about ORIGIN, not value, and the two do not coincide: the SimpleFilters
      # form is a plain GET that submits every control it renders, so emptying a select
      # arrives as `q[genre_eq]=` — an explicit choice whose value happens to be blank.
      # {#active_simple_filters} cannot tell that apart from a URL that mentioned no
      # filter at all, and the difference decides whether the request is storing state
      # or restoring it.
      #
      # @param params [ActionController::Parameters, Hash] the `q` params as they arrived
      # @return [Boolean]
      def simple_filter_params?(params)
        return false if params.blank?

        simple_filter_param_names.any? { |key| params.key?(key) }
      end

      # Replace the simple filter values with the ones a saved view carries. A view
      # is a complete state and not a merge, so whatever came in the URL is dropped
      # — the same contract {FilterForm#apply_saved_view_state} applies to the
      # declared attributes.
      def apply_simple_filter_state(values)
        @q_params = (values || {}).to_h.stringify_keys
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
          key = simple_filter_key(filter[:attribute], predicate)

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

      # The same keys, flattened for lookup. {#simple_filters_permitted_keys} is shaped for
      # `permit`, where a toggle group is a `{key => []}` entry rather than a bare name.
      #
      # @return [Array<String>]
      def simple_filter_param_names
        simple_filters_permitted_keys.flat_map { |key| key.is_a?(Hash) ? key.keys : key }.map(&:to_s)
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
        params.merge!(active_simple_filters(include_date_ranges: false))
      end

      # The key a simple filter travels under. `predicate` is nil for a date range,
      # which has no single Ransack predicate.
      def simple_filter_key(attribute, predicate)
        predicate.present? ? "#{attribute}_#{predicate}" : attribute.to_s
      end

      # Get current value for a simple filter from params
      def current_simple_filter_value(attribute, predicate = :eq)
        key = predicate.present? ? "#{attribute}_#{predicate}" : attribute.to_s

        # 1. Try raw params first (for non-persisted immediate feedback)
        value = nil
        value = @q_params[key] || @q_params[key.to_sym] if defined?(@q_params) && @q_params.present?

        # 2. Try instance attribute (for persisted/restored values)
        value ||= send(key) if attributes_initialized? && respond_to?(key)

        if value.is_a?(Array)
          return value.compact_blank
        end

        value
      end

      # Whether this form has run ActiveModel's own initializer yet.
      #
      # `respond_to?` on an ActiveModel raises before it has: the dispatch reads
      # `@attributes`, which `super(attributes)` sets at the very END of
      # {FilterForm#initialize}. The persistence write asks for the active simple filters
      # from inside `fetch_stored_filter_state`, which necessarily runs before that — what
      # it writes is part of what it then hands to `super`.
      #
      # Nothing is lost by skipping the fallback there: at that point everything the request
      # carries still lives in `@q_params`, which step 1 already read. The fallback exists
      # for the render that comes after, where a value restored into a declared attribute is
      # the only copy left.
      def attributes_initialized?
        defined?(@attributes) && !@attributes.nil?
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
      # `label: false` es "no quiero rótulo"; `nil` o ausente sigue siendo "derivalo". Con
      # el `||` que había acá los dos eran falsy y los dos caían a la derivación, así que
      # no había forma de pedir un filtro sin caption. La plantilla sí sabe no pintarlo
      # —`if filter[:label].present?`— lo que no dejaba llegar un rótulo vacío era esto.
      #
      # Importa porque lo derivado suele ser peor que nada: `infer_simple_filter_label`
      # humaniza el nombre del atributo RANSACK, no el del campo, así que un
      # `simple_filter :roles_name` sin `label:` pinta "Roles name" —el predicado,
      # humanizado y en inglés— en una UI en español; el fallback de I18n tampoco alcanza
      # ahí, porque `roles_name` no es un atributo del modelo sino un camino por una
      # asociación.
      #
      # El centinela es `false` y NO la ausencia de la clave, aunque distinguir "no me la
      # pasaron" sería más elegante: no se puede. `simple_filter` delega en
      # `filter_attribute`, que guarda `explicit_label: label` siempre, y
      # `defined_simple_filters` reconstruye el hash con `label:` fijo. O sea que
      # `filter.key?(:label)` es SIEMPRE true y, usado como condición, dejaría a todos los
      # filtros sin rótulo. `explicit_label` sí conserva el `false`, que es lo que hace
      # que este camino funcione.
      #
      # El rótulo del panel avanzado no se toca: `filter_attributes` guarda
      # `label: label || key.to_s.humanize` aparte, así que una fila del popover sigue
      # teniendo nombre, que es lo que ahí hace falta.
      def simple_filter_label(filter)
        return nil if filter[:label] == false

        resolve_definition_value(filter[:label]) || infer_simple_filter_label(filter[:attribute])
      end

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
