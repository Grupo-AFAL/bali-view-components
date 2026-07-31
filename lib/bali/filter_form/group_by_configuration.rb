# frozen_string_literal: true

module Bali
  class FilterForm
    # GroupByConfiguration provides DSL and methods for query-aware row grouping.
    #
    # Grouping is driven by a whitelisted top-level `group_by` param (NOT a
    # `q[...]` Ransack predicate). When APPLIED (see {#group_by_applied}) it:
    #   1. orders the query by the group field FIRST (user column sorts become
    #      secondary, giving sort-within-groups), and
    #   2. exposes GLOBAL per-group counts over the full filtered (unpaginated)
    #      result via {#group_counts}.
    #
    # Tres preguntas distintas, tres predicados — confundirlos es EL bug de este módulo:
    #   * ESTADO      — {#group_by} / {#group_by_active?}: ¿hay una agrupación elegida?
    #     Manda la PRESERVACIÓN (hidden fields, caché, payload de vistas guardadas).
    #   * MODO        — {#group_by_applies?}: ¿este modo de visualización aplica agrupación?
    #     Manda la VISIBILIDAD del control.
    #   * APLICACIÓN  — {#group_by_applied} / {#group_by_applied?}: ¿se está aplicando ahora?
    #     Manda ordenamiento, conteos y bandas de grupo.
    #
    # Security boundary: the raw param NEVER reaches `.group()`/`.order()`.
    # {#resolve_group_by} returns the declared symbol only when the raw value
    # matches a declared attribute; anything else resolves to nil. Ransack does
    # not authorize `.group`, so this whitelist is the only gate.
    #
    # @example Class-level DSL
    #   class MoviesFilterForm < Bali::FilterForm
    #     group_by_attribute :genre, label: "Género"
    #     group_by_attribute :status
    #   end
    #
    # @example Instance-level configuration
    #   FilterForm.new(Movie.all, params, group_by_attributes: [:genre, :status])
    #
    module GroupByConfiguration
      extend ActiveSupport::Concern

      # Modos de visualización en los que la agrupación se APLICA. Una tabla es la única
      # superficie de filas contiguas donde una banda de grupo significa algo: en tarjetas o
      # en una línea de tiempo el mismo ordenamiento actúa INVISIBLE, reacomodando el
      # contenido sin que nada en pantalla lo explique.
      DEFAULT_GROUP_BY_MODES = %i[table].freeze

      class_methods do
        # Storage for group_by attribute definitions
        def defined_group_by_attributes
          @defined_group_by_attributes ||= []
        end

        # Declare an attribute users can group rows by.
        #
        # @param attribute [Symbol] Column name to group by (must be a real
        #   column / ransackable sort attribute on the scope's model)
        # @param label [String, nil] Human-readable label (defaults to inferred)
        def group_by_attribute(attribute, label: nil)
          defined_group_by_attributes << { attribute: attribute.to_sym, label: label }
        end

        # Inherit group_by attributes from parent class
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@defined_group_by_attributes, defined_group_by_attributes.dup)
        end
      end

      # Normalized group_by definitions ({attribute:, label:}).
      # Prefers instance-level configuration over the class DSL.
      #
      # @return [Array<Hash>]
      def group_by_definitions
        @group_by_definitions ||= normalize_group_by_attributes(
          @instance_group_by_attributes.presence || self.class.defined_group_by_attributes
        )
      end

      # Declared group_by attribute names (the whitelist).
      #
      # @return [Array<Symbol>]
      def group_by_attributes
        group_by_definitions.map { |definition| definition[:attribute] }
      end

      # Whether grouping is available (any attribute declared).
      #
      # @return [Boolean]
      def group_by_enabled?
        group_by_definitions.present?
      end

      # The active group_by attribute (declared symbol) or nil.
      #
      # @return [Symbol, nil]
      def group_by
        @group_by
      end

      # Whether a valid group_by is currently active (ESTADO).
      #
      # @return [Boolean]
      def group_by_active?
        !@group_by.nil?
      end

      # ¿La agrupación APLICA en el modo de visualización actual? Pregunta sobre el MODO, no
      # sobre el estado: es true en la tabla aunque nadie haya elegido agrupar. Sin modo (un
      # listado sin view switch, o uno que todavía no sabe cuál renderiza) aplica, que es el
      # caso de la enorme mayoría; un listado cuya vista por default NO es la tabla tiene que
      # pasarle ese modo al form (ver el `display_mode:` de FilterForm#initialize).
      #
      # `[]` corta antes: es la forma de decir "ningún modo la aplica", y el escape de "sin
      # modo aplica" la habría vuelto a encender en cada URL sin `?view=`.
      #
      # @return [Boolean]
      def group_by_applies?
        return false if group_by_modes.empty?

        @display_mode.nil? || group_by_modes.include?(@display_mode)
      end

      # La agrupación que se está APLICANDO (o nil): manda ordenamiento, conteos y bandas.
      # Fuera de un modo que la aplique es nil AUNQUE {#group_by} siga elegido — eso es la
      # suspensión. Derivado y no `@group_by = nil` a propósito: el estado tiene que
      # sobrevivir en la URL, en la caché de filtros y en el payload de una vista guardada.
      #
      # @return [Symbol, nil]
      def group_by_applied
        group_by_applies? ? @group_by : nil
      end

      # @return [Boolean]
      def group_by_applied?
        !group_by_applied.nil?
      end

      # Hay agrupación elegida pero este modo no la aplica. Azúcar para que el host pueda
      # explicarlo ("Agrupado por Género — se aplica en la vista de tabla").
      #
      # @return [Boolean]
      def group_by_suspended?
        group_by_active? && !group_by_applies?
      end

      # Modos de visualización que aplican la agrupación, normalizados a símbolos.
      #
      # `nil` y `[]` NO son lo mismo, así que no se puede usar `.presence`: `[]` es un host
      # diciendo "ningún modo la aplica" (quiere el param en las vistas guardadas pero nunca
      # aplicado) y colapsarlo al default le daba exactamente lo contrario, en silencio.
      #
      # @return [Array<Symbol>]
      def group_by_modes
        @group_by_modes ||= begin
          declared = @instance_group_by_modes.nil? ? DEFAULT_GROUP_BY_MODES : @instance_group_by_modes
          Array(declared).map(&:to_sym)
        end
      end

      # Options for the "Agrupar por" UI control, labels resolved.
      #
      # @return [Array<Hash>] each {attribute:, label:}
      def group_by_options
        group_by_definitions.map do |definition|
          {
            attribute: definition[:attribute],
            label: definition[:label] || infer_group_by_label(definition[:attribute])
          }
        end
      end

      # Global per-group counts over the FULL filtered (unpaginated) result.
      # Independent of Pagy — the controller paginates the relation, this counts
      # the whole query. `unscope(:order)` is required because ORDER BY conflicts
      # with GROUP BY under strict SQL modes.
      #
      # Keys are whatever SQL returns (strings, enum labels, nil). Returns {}
      # when grouping is inactive OR suspended (ver {#group_by_applied}).
      #
      # @return [Hash] value => Integer count
      def group_counts
        return {} unless group_by_applied?

        @group_counts ||= result.unscope(:order).group(group_by_applied).count
      end

      private

      # Resolve the raw param to a declared attribute symbol, or nil.
      # This is the security boundary: the returned symbol always comes from the
      # whitelist, never from the raw param.
      def resolve_group_by(raw_value)
        return nil if raw_value.blank?

        group_by_attributes.find { |attribute| attribute.to_s == raw_value.to_s }
      end

      # Prepend the group field as the primary sort so rows cohere into groups,
      # keeping any user column sort as the secondary sort (sort-within-groups).
      # Ransack whitelists sort columns, so building the `s` array is safe.
      #
      # Gatea por APLICACIÓN y no por estado: en tarjetas este ordenamiento reacomodaría el
      # contenido sin ninguna banda de grupo que lo explique.
      def apply_group_by_ordering(params)
        applied = group_by_applied
        return params if applied.nil?

        existing_sort = Array(params["s"]).compact_blank
        params["s"] = [ "#{applied} asc", *existing_sort ]
        params
      end

      def normalize_group_by_attributes(attributes)
        attributes.map do |attribute|
          if attribute.is_a?(Hash)
            { attribute: attribute[:attribute].to_sym, label: attribute[:label] }
          else
            { attribute: attribute.to_sym, label: nil }
          end
        end
      end

      # Infer a label from the attribute name using I18n or humanization,
      # mirroring SimpleFiltersConfiguration#infer_simple_filter_label.
      def infer_group_by_label(attribute)
        if respond_to?(:scope) && scope.respond_to?(:model)
          model_name = scope.model.model_name.i18n_key
          translated = I18n.t("activerecord.attributes.#{model_name}.#{attribute}", default: nil)
          return translated if translated
        end

        attribute.to_s.humanize
      end
    end
  end
end
