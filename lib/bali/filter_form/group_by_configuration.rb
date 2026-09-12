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
    # Se puede agrupar por lo MISMO que se puede ordenar —una columna, un `ransacker` o un
    # camino de asociación—, porque el `GROUP BY` sale del mismo Arel que el `ORDER BY`
    # (ver {#group_by_expression}). Leer la banda de una fila es la otra mitad, y es una
    # pregunta de Ruby, no de SQL: {#group_value_for}.
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
        # Acepta lo MISMO que el ordenamiento: una columna real, un `ransacker` o un camino
        # de asociación (`worker_legal_entity_name`). El `GROUP BY` sale del mismo Arel que
        # Ransack le da al `ORDER BY`, así que las dos mitades de una agrupación —el orden
        # que junta las filas y el conteo que las cuenta— no se pueden desincronizar (#1102).
        #
        # @param attribute [Symbol] Columna, ransacker o camino de asociación
        # @param label [String, nil] Human-readable label (defaults to inferred)
        # @param sql [String, Arel::Nodes::Node, Proc, nil] Expresión explícita para el
        #   GROUP BY, para lo que ni una columna ni un ransacker pueden decir. Un String pasa
        #   por `Arel.sql`: es SQL del desarrollador, nunca del usuario. Cuando se declara
        #   manda TAMBIÉN sobre el ORDER BY (ver {#apply_group_by_sql_order}), porque una
        #   agrupación ordenada por una expresión distinta de la que agrupa no junta nada.
        # @param value [Proc, nil] Cómo leer la banda de UNA fila (ver {#group_value_for}).
        #   Por default `record.public_send(attribute)`, que para un camino de asociación
        #   (`worker_legal_entity_id`) es un NoMethodError — de ahí este hook. Tiene que
        #   devolver el MISMO valor que devolvió el GROUP BY: la búsqueda del conteo global
        #   es por valor (ver {#group_counts} y Bali::Table#global_group_count).
        def group_by_attribute(attribute, label: nil, sql: nil, value: nil)
          defined_group_by_attributes << {
            attribute: attribute.to_sym, label: label, sql: sql, value: value
          }
        end

        # Inherit group_by attributes from parent class
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@defined_group_by_attributes, defined_group_by_attributes.dup)
        end
      end

      # Normalized group_by definitions ({attribute:, label:, sql:, value:}).
      # Prefers instance-level configuration over the class DSL. Validating here y no en el
      # `group_by_attribute` es lo único posible: el modelo entra con el scope, o sea recién
      # al construir el form.
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

        @group_counts ||= begin
          relation = result.unscope(:order)
          relation.group(group_by_expression).count
        end
      end

      # La expresión sobre la que corre el `GROUP BY`, o nil cuando no hay agrupación
      # aplicada. Tres orígenes, en orden:
      #
      #   1. el `sql:` declarado, si lo hay;
      #   2. el Arel que Ransack le da al ORDER BY — que es lo que hace que un `ransacker` o
      #      un camino de asociación agrupen, no solo ordenen (#1102). El join ya está en la
      #      relación: la agrupación se prepende como sort ANTES de que se evalúe `result`,
      #      así que para cuando esto corre Ransack ya lo armó y el bind está memoizado;
      #   3. el símbolo pelado, que es lo que hacía v3.1: una columna real que el host no
      #      puso en `ransackable_attributes` sigue agrupando como siempre.
      #
      # @return [Arel::Nodes::Node, Arel::Attributes::Attribute, Symbol, nil]
      def group_by_expression
        return nil unless group_by_applied?

        @group_by_expression ||=
          explicit_group_by_sql(group_by_applied) ||
          ransack_group_by_expression(group_by_applied) ||
          group_by_applied
      end

      # La banda a la que pertenece UNA fila bajo la agrupación aplicada, o nil cuando no hay
      # ninguna (apagada o suspendida) — o sea, exactamente lo que va en `with_row(group:)`.
      #
      # El default es `record.public_send(attribute)`, que alcanza para una columna y para un
      # ransacker con gemelo en Ruby. Para un camino de asociación NO existe tal método y por
      # eso la declaración puede traer un `value:`; la validación no deja pasar el caso en el
      # que no hay ni uno ni otro, para que el NoMethodError no aparezca recién al pintar.
      #
      # @param record [Object] el registro de la fila
      # @return [Object, nil] el valor CRUDO del grupo (el mismo que la llave de group_counts)
      def group_value_for(record)
        applied = group_by_applied
        return nil if applied.nil?

        reader = group_by_definition_for(applied)[:value]
        return reader.call(record) if reader.respond_to?(:call)

        record.public_send(applied)
      end

      private

      # Resolve the raw param to a declared attribute symbol, or nil.
      # This is the security boundary: the returned symbol always comes from the
      # whitelist, never from the raw param.
      #
      # Toca `group_by_definitions` ANTES del `blank?` y a propósito: ahí es donde se validan
      # las declaraciones, y esto corre en el initialize venga o no el param. Al revés, una
      # declaración rota se descubría recién cuando alguien elegía esa agrupación en la
      # pantalla — el contrato de arranque que ya tienen `input:` y `auto_submit:` (#1102).
      def resolve_group_by(raw_value)
        return nil if group_by_definitions.empty?
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
        return params if group_by_definition_for(applied)[:sql]

        existing_sort = Array(params["s"]).compact_blank
        params["s"] = [ "#{applied} asc", *existing_sort ]
        params
      end

      # El ORDER BY de una agrupación con `sql:` explícito, que Ransack no puede armar: su
      # param `s` solo habla de nombres, y una expresión no tiene nombre. Se aplica sobre la
      # relación ya evaluada, prependiendo la MISMA expresión que agrupa y conservando el
      # orden del usuario detrás (sort-within-groups, igual que la otra mitad).
      def apply_group_by_sql_order(relation)
        return relation unless group_by_applied?
        return relation unless group_by_definition_for(group_by_applied)[:sql]

        relation.reorder(Arel::Nodes::Ascending.new(group_by_expression), *relation.order_values)
      end

      # El `sql:` declarado, resuelto. Un String se envuelve en `Arel.sql` — viene de la
      # declaración del desarrollador, nunca de la URL (el param crudo no llega hasta acá:
      # ver {#resolve_group_by}).
      def explicit_group_by_sql(attribute)
        sql = group_by_definition_for(attribute)[:sql]
        return nil if sql.nil?

        expression = resolve_definition_value(sql)
        expression.is_a?(String) ? Arel.sql(expression) : expression
      end

      # El Arel que Ransack usa para ORDENAR por este nombre. Es literalmente el nodo de sort
      # que la agrupación ya prepende, construido de nuevo contra el MISMO contexto: los binds
      # están memoizados, así que no agrega un join extra ni un alias distinto. nil cuando el
      # nombre no es ordenable por Ransack (una columna fuera de `ransackable_attributes`),
      # que es cuando cae al símbolo pelado de siempre.
      def ransack_group_by_expression(attribute)
        sort = Ransack::Nodes::Sort.extract(ransack_search.context, attribute.to_s)
        sort&.valid? ? sort.attr : nil
      end

      def group_by_definition_for(attribute)
        group_by_definitions.find { |definition| definition[:attribute] == attribute } || {}
      end

      def normalize_group_by_attributes(attributes)
        attributes.map do |attribute|
          definition =
            if attribute.is_a?(Hash)
              { attribute: attribute[:attribute].to_sym, label: attribute[:label],
                sql: attribute[:sql], value: attribute[:value] }
            else
              { attribute: attribute.to_sym, label: nil, sql: nil, value: nil }
            end

          validate_group_by_definition!(definition)
          definition
        end
      end

      # Revienta al CONSTRUIR el form, no cuando alguien elige la agrupación en la pantalla.
      # Hasta v3.1 `group_by_attribute :lo_que_sea` se aceptaba sin chistar y el símbolo
      # llegaba crudo al SQL: `PG::UndefinedColumn` en producción, sobre una pantalla que
      # había cargado bien mil veces (#1102).
      #
      # Las dos mitades se verifican por separado porque fallan por separado: una agrupación
      # puede tener un GROUP BY perfecto y no tener cómo leer la banda de una fila.
      def validate_group_by_definition!(definition)
        model = group_by_model
        return if model.nil?

        attribute = definition[:attribute]
        validate_group_by_expression!(model, definition, attribute)
        validate_group_by_reader!(model, definition, attribute)
      end

      def validate_group_by_expression!(model, definition, attribute)
        return if definition[:sql]
        return if group_by_resolvable?(model, attribute)

        raise ArgumentError,
              "group_by_attribute :#{attribute}: #{model.name} has no column, ransacker or " \
              "reachable association path by that name, so the GROUP BY would reach the " \
              "database as a bare identifier and fail there. Declare a ransacker on the " \
              "model, use the association path Ransack already sorts by, or pass `sql:`."
      end

      def validate_group_by_reader!(model, definition, attribute)
        return if definition[:value]
        return if model.column_names.include?(attribute.to_s)
        return if model.method_defined?(attribute)

        raise ArgumentError,
              "group_by_attribute :#{attribute}: the GROUP BY resolves but a row cannot be " \
              "read — #{model.name} answers no `##{attribute}`, so each row's band would " \
              "raise NoMethodError while painting. Pass `value:` (e.g. " \
              "`value: ->(record) { record.worker&.legal_entity_id }`)."
      end

      # Una columna real primero: es lo que v3.1 aceptaba y sigue valiendo aunque el host la
      # deje fuera de `ransackable_attributes` (agrupa; lo que no hace es ordenar). Después,
      # lo que Ransack puede resolver — ransackers y caminos de asociación —, con la MISMA
      # autorización que aplica al ordenar.
      def group_by_resolvable?(model, attribute)
        return true if model.column_names.include?(attribute.to_s)

        group_by_probe_context.attribute_method?(attribute.to_s)
      end

      # Contexto de solo lectura para validar nombres. Deliberadamente NO es el de
      # `ransack_search`: ese todavía no existe cuando se construye el form (depende de los
      # atributos que el initialize asigna al final) y bindear contra él agregaría joins por
      # una simple verificación. `attribute_method?` recorre asociaciones sin construir
      # ninguna.
      def group_by_probe_context
        @group_by_probe_context ||= Ransack::Context.for(scope)
      end

      # El modelo contra el que se validan las declaraciones, o nil cuando el scope no es una
      # relación de ActiveRecord: sin modelo no hay nada que verificar y la validación se
      # salta entera.
      def group_by_model
        return scope.model if scope.respond_to?(:model)
        return scope if scope.is_a?(Class) && scope.respond_to?(:ransack)

        nil
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
