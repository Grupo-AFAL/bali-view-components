# frozen_string_literal: true

require_relative "filter_form/search_configuration"
require_relative "filter_form/filter_group_parser"
require_relative "filter_form/simple_filters_configuration"
require_relative "filter_form/group_by_configuration"
require_relative "filter_form/saved_views_configuration"
require_relative "filter_form/enum_casting"

module Bali
  # FilterForm provides a unified interface for Ransack-based filtering with support
  # for both simple filters and complex AND/OR grouped conditions.
  #
  # @example Basic usage with attribute DSL
  #   class UsersFilterForm < Bali::FilterForm
  #     # Declare quick search fields (searches across multiple columns)
  #     search_fields :name, :email
  #
  #     # Declare filterable attributes for Filters UI
  #     filter_attribute :name, type: :text
  #     filter_attribute :email, type: :text
  #     filter_attribute :status, type: :select,
  #                      options: [['Active', 'active'], ['Inactive', 'inactive']]
  #     filter_attribute :created_at, type: :date
  #
  #     # Standard Ransack attributes for simple filtering
  #     attribute :name_cont
  #     attribute :status_eq
  #   end
  #
  #   # In controller
  #   @filter_form = UsersFilterForm.new(User.all, params, storage_id: 'users')
  #   @users = @filter_form.result
  #
  #   # In view - everything auto-configured from FilterForm
  #   data_table.with_filters_panel
  #
  # @example Using search_fields without subclassing
  #   @filter_form = Bali::FilterForm.new(
  #     Movie.all,
  #     params,
  #     search_fields: [:name, :genre, :tenant_name]
  #   )
  #
  class FilterForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include SearchConfiguration
    include FilterGroupParser
    include SimpleFiltersConfiguration
    include GroupByConfiguration
    include SavedViewsConfiguration
    include EnumCasting

    attr_reader :scope, :storage_id, :context, :clear_filters, :groupings, :view_param, :display_mode

    # Param que lleva el modo de visualización. Es EL MISMO que el `view_param:` del
    # DataTable: UNA sola literal para que no se puedan desincronizar (el DataTable revienta
    # temprano si difieren, ver Bali::DataTable::Component#initialize).
    DEFAULT_VIEW_PARAM = :view

    # Ransack attribute for receiving the sort parameters
    attribute :s

    class << self
      # Widgets available in the SimpleFilters UI (valid `input:` values)
      SIMPLE_INPUTS = %i[select slim_select toggle_group radio_group boolean date
                         date_range number_range].freeze

      # Default SimpleFilters widget derived from the declared data type.
      # :text has no entry on purpose — quick text search belongs to search_fields.
      DEFAULT_SIMPLE_INPUT_FOR_TYPE = {
        select: :select, boolean: :boolean, date: :date, datetime: :date, number: :number_range
      }.freeze

      # Storage for filter attribute definitions used by Filters UI
      def filter_attributes
        @filter_attributes ||= []
      end

      # Define a filterable attribute. One declaration can feed BOTH filter UIs:
      # the advanced Filters popover (via #available_attributes) and, when
      # `simple: true`, the inline SimpleFilters row (via #simple_filters_config).
      #
      # @param key [Symbol] Attribute key (column name or Ransack association path)
      # @param type [Symbol] Data type: :text, :number, :date, :datetime,
      #   :select, :boolean. Drives the advanced UI operators and the default
      #   simple widget.
      # @param label [String, Proc, false] Human-readable label (defaults to humanized key).
      #   Zero-arity procs are resolved per-instance with instance_exec (useful
      #   for I18n lookups that must not be frozen at class-load time).
      #   `false` means "no caption" in the SimpleFilters row, for a control that
      #   already names itself through its blank option ("All roles"). It is not
      #   the same as omitting it: omitted derives one from the Ransack attribute
      #   name, which for a path through an association is the predicate humanized
      #   in English. The advanced popover keeps a label either way — a row there
      #   needs a name.
      # @param options [Array, Proc] For select types, array of [label, value]
      #   pairs or a zero-arity proc resolved per-instance with instance_exec —
      #   inside it you can use `scope` (the relation the controller passed in,
      #   typically already narrowed to the policy scope).
      # @param collection [Array, Proc] Alias of options, matching the key name
      #   the instance-level `simple_filters:` hashes use
      # @param simple [Boolean] Also render this attribute in the SimpleFilters UI
      # @param advanced [Boolean] Offer this attribute in the Filters popover
      #   (default true; pass false for an attribute that only belongs in the
      #   inline SimpleFilters row)
      # @param input [Symbol] SimpleFilters widget when it differs from the one
      #   derived from type (e.g. type: :select, input: :slim_select)
      # @param predicate [Symbol] Fixed Ransack predicate for the simple UI
      #   (default :eq; the advanced UI lets the user pick the operator)
      # @param blank [String, Proc] Blank option text for the simple UI
      # @param default [String] Default value for the simple UI
      # @param icon [String] Icon name for the simple UI
      # @param step [Numeric] Step for the :number_range simple widget
      # @param placeholder_min [String] Min placeholder for :number_range
      # @param placeholder_max [String] Max placeholder for :number_range
      #
      # @example Advanced popover only (same as always)
      #   filter_attribute :name, type: :text
      #
      # @example Both UIs, collection narrowed to the policy scope
      #   filter_attribute :pm_id, type: :select, simple: true,
      #     options: -> { User.where(id: scope.select(:pm_id)).pluck(:name, :id) }
      #
      # @example Simple UI only, custom widget
      #   filter_attribute :priority, type: :select, simple: true, advanced: false,
      #     options: [['High', 'high'], ['Low', 'low']], input: :toggle_group
      # rubocop:disable Metrics/ParameterLists
      def filter_attribute(key, type: :text, label: nil, options: [], collection: nil,
                           simple: false, advanced: true, input: nil, predicate: :eq,
                           blank: nil, default: nil, icon: nil, step: nil,
                           placeholder_min: nil, placeholder_max: nil)
        # rubocop:enable Metrics/ParameterLists
        type = type.to_sym
        filter_attributes << {
          key: key.to_sym,
          type: type,
          label: label || key.to_s.humanize,
          explicit_label: label,
          options: options.presence || collection || [],
          simple: simple,
          advanced: advanced,
          input: simple ? resolve_simple_input(key, type, input) : input&.to_sym,
          predicate: predicate&.to_sym,
          blank: blank,
          default: default,
          icon: icon,
          step: step,
          placeholder_min: placeholder_min,
          placeholder_max: placeholder_max
        }
      end

      # Inherit filter_attributes from parent class
      # Note: search_fields inheritance is handled by SearchConfiguration concern
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@filter_attributes, filter_attributes.dup)
      end

      private

      # Validate an explicit simple `input:` or derive it from the data type.
      # Fails fast at class-definition time so a typo'd widget never renders
      # silently as a plain select.
      def resolve_simple_input(key, type, input)
        if input
          input = input.to_sym
          return input if SIMPLE_INPUTS.include?(input)

          raise ArgumentError, "filter_attribute #{key}: unknown input: :#{input} " \
                               "(valid: #{SIMPLE_INPUTS.join(', ')})"
        end

        DEFAULT_SIMPLE_INPUT_FOR_TYPE.fetch(type) do
          raise ArgumentError, "filter_attribute #{key}: type :#{type} has no simple filter " \
                               "widget; pass input: (one of #{SIMPLE_INPUTS.join(', ')}) or " \
                               "declare quick text search with search_fields"
        end
      end
    end

    # @param scope [ActiveRecord::Relation] The base scope to filter
    # @param params [Hash, ActionController::Parameters] Request params containing q[...]
    # @param storage_id [String] Optional cache key for persisting filters
    # @param context [String] Optional context for cache key namespacing
    # @param search_fields [Array<Symbol>] Fields for quick text search (alternative to DSL)
    # @param search_placeholder [String] Placeholder text for search input
    # @param persist_enabled [Boolean] Whether user has opted into filter persistence
    #   (default: false). When false, filters are saved but not restored.
    # @param simple_filters [Array<Hash>] Simple inline filters (alternative to DSL)
    # @param saved_views_store [Object, Symbol] Store for named saved views — an
    #   app-provided object with the list/find/save/delete contract, or `:default` for the
    #   engine's own storage (Bali::SavedView) scoped to `saved_views_owner:` and
    #   `storage_id:` (see SavedViewsConfiguration)
    # @param saved_views_owner [Object] Owner of the `:default` store (e.g. current_user);
    #   ignored when an explicit store object is given
    # @param group_by_modes [Array<Symbol>] Modos de visualización que APLICAN la agrupación
    #   (default `[:table]`). Fuera de ellos la agrupación se suspende: el control se esconde
    #   y el ordenamiento no corre, pero el param sobrevive (ver GroupByConfiguration)
    # @param view_param [Symbol] Param de la URL que lleva el modo de visualización
    #   (default `:view`). Tiene que ser el MISMO que el del DataTable
    # @param display_mode [Symbol, String] Modo que el listado va a RENDERIZAR, cuando el
    #   param de la URL no alcanza para saberlo: un listado cuya vista por default no es la
    #   tabla (el view switch declara las tarjetas primero) aterriza sin `?view=` y el form,
    #   mirando solo la URL, creería que está en la tabla y aplicaría la agrupación sobre las
    #   tarjetas. Pasá lo MISMO que le pasás al DataTable (p.ej. `params[:view] || :grid`)
    # rubocop:disable Metrics/ParameterLists
    def initialize(scope, params = {}, storage_id: nil, context: nil, search_fields: nil,
                   search_placeholder: nil, search_icon: nil, persist_enabled: false, simple_filters: nil,
                   group_by_attributes: nil, group_by_modes: nil, view_param: nil, display_mode: nil,
                   saved_views_store: nil, saved_views_owner: nil)
      # rubocop:enable Metrics/ParameterLists
      @scope = scope
      @storage_id = storage_id
      @context = context
      @instance_search_fields = search_fields&.map(&:to_sym)
      @instance_search_icon = search_icon
      @instance_simple_filters = simple_filters
      @instance_group_by_attributes = group_by_attributes
      @instance_group_by_modes = group_by_modes
      @view_param = (view_param || DEFAULT_VIEW_PARAM).to_sym
      @search_placeholder = search_placeholder
      @persist_enabled = persist_enabled
      @clear_filters = params.fetch(:clear_filters, false)
      @clear_search = params.fetch(:clear_search, false)
      @saved_views_store = resolve_saved_views_store(saved_views_store, saved_views_owner)
      @saved_view_param = params[:saved_view].presence
      # ORIGEN vs APLICACIÓN, la misma separación que group_by. `saved_view` APLICA (pisa el
      # estado con el payload) y por eso #669 lo sacó de los forms de filtro: preservarlo
      # re-aplicaba la vista encima de lo que el usuario acababa de teclear. Pero al perderlo
      # también se pierde SABER de qué vista venía el estado, y sin eso no se puede ofrecer
      # "Actualizar 'X'". `view_origin` es ese dato y NUNCA se aplica: solo recuerda.
      @saved_view_origin_param = params[:view_origin].presence || @saved_view_param
      @group_by = resolve_group_by(params[:group_by])
      # Que el param VENGA es distinto de que traiga un valor válido: "sin agrupación" llega
      # como `?group_by=` y tiene que ganarle a la agrupación guardada en la caché de filtros
      # (ver #fetch_stored_filter_state). Sin esta distinción, apagar la agrupación con la
      # persistencia encendida la resucitaba en el próximo render.
      @group_by_requested = params.key?(:group_by)
      # La agrupación se SUSPENDE fuera de los modos que la aplican (default: tabla), pero el
      # param sigue vivo: volver a la tabla la encuentra como se dejó. El modo que pasa el
      # host gana sobre la URL: es el único que sabe qué vista renderiza un listado que
      # todavía no tiene `?view=` (ver el @param display_mode). `.to_s` primero porque esto
      # llega crudo de la URL y un param anidado (`?view[]=x`) no responde a `to_sym`; un
      # valor desconocido simplemente no está en group_by_modes y suspende, que es el lado
      # seguro (agrupar de más es lo que no se ve venir).
      @display_mode = (display_mode || params[@view_param]).to_s.presence&.to_sym

      q_params = params.fetch(:q, {})
      @q_params = q_params # Store for simple_filters value extraction
      perm_attrs = permitted_attributes
      permitted = q_params.permit(perm_attrs)
      permitted_h = permitted.to_h
      attributes = permitted_h.select { |k, _| self.class.attribute_names.include?(k.to_s) }

      # Extract Ransack groupings (g) and combinator (m) for complex filters
      # These are used by Filters for AND/OR condition groups
      @groupings = extract_groupings(q_params)
      @combinator = q_params[:m]

      # Capture quick search value from params
      @search_value = extract_search_value(q_params)

      # Permit simple filter keys on @q_params so values can be read via
      # current_simple_filter_value. These are NOT added to `attributes` —
      # simple filter values bypass ActiveModel and go straight to Ransack.
      @q_params = q_params.permit(perm_attrs) if self.simple_filters_enabled?

      # Vista guardada aplicada por URL (?saved_view=<id>): su payload REEMPLAZA el estado
      # que hubiera venido en q — una vista es un estado completo, no un merge. Va ANTES de
      # la persistencia para que el estado de la vista se escriba como "último estado" del
      # listado (fetch_stored_filter_state lo ve como filtros recién enviados).
      saved_view_applied = current_saved_view.present?
      attributes = apply_saved_view_state if saved_view_applied

      # Persist/restore all filter state (attributes, groupings, combinator, search)
      if storage_id.present?
        attributes, @groupings, @combinator, @search_value = fetch_stored_filter_state(
          attributes, @groupings, @combinator, @search_value, force_write: saved_view_applied
        )
      end

      super(attributes)
    end

    # Check if user has opted into filter persistence
    def persist_enabled?
      @persist_enabled
    end

    def permitted_attributes
      (scalar_attributes + date_range_attributes + array_attributes.map { |a| { a => [] } } +
       simple_filters_permitted_keys).uniq
    end

    # To define array attributes the user needs to specify an array as
    # it's default value.
    #
    # e.g.
    # attribute :vendors_id_in, default: []
    #
    def array_attributes
      @array_attributes ||= self.class.attribute_names.select do |attribute_name|
        array_predicates.any? { |predicate| attribute_name.to_s.ends_with?(predicate) }
      end
    end

    def scalar_attributes
      @scalar_attributes ||= self.class._default_attributes.keys - non_scalar_attributes
    end

    def non_scalar_attributes
      @non_scalar_attributes ||= array_attributes + date_range_attributes
    end

    def date_range_attributes
      @date_range_attributes ||= begin
        class_date_range_attrs = self.class.attribute_names.filter do |key|
          self.class.attribute_types[key].instance_of?(Bali::Types::DateRangeValue)
        end
        (class_date_range_attrs + simple_date_range_attributes.map(&:to_s)).uniq
      end
    end

    silence_warnings do
      def model_name
        @model_name ||= ActiveModel::Name.new(self, nil, "q")
      end
    end

    def inspect
      "<#{self.class.name} attributes=[#{attribute_names.join(',')}]>"
    end

    def id
      @id ||= scope.cache_key
    end

    def cache_key
      @cache_key ||= "#{self.class.name.tableize};#{context};#{storage_id}"
    end

    # How many values are narrowing this listing right now. The quick search counts
    # as one: it cuts the result exactly like any other filter, and a toolbar that
    # reads "0 filters" over 3 of 200 rows is telling the user something false.
    def active_filters_count
      active_filters.size
    end

    def active_filters?
      active_filters.any?
    end

    # Every value narrowing the listing right now, keyed the way the query carries
    # it. Three sources, because a listing can be narrowed from three places and
    # only the first used to be represented here:
    #
    #   - attributes declared with the `filter_attribute` DSL, via `query_params`;
    #   - the simple filters, which never become ActiveModel attributes — a plain
    #     `FilterForm.new(scope, params, simple_filters: [...])` declares none, so
    #     `attribute_names` is just `["s"]` and this answered `{}` no matter what
    #     the user had chosen;
    #   - the quick search box, whose value never lived in `query_params` either.
    #
    # That mattered beyond the count: `Table` picks its empty state from
    # `active_filters?`, so a search or a simple filter that cut the result to zero
    # got "No records yet" plus an invitation to create one, instead of "No results"
    # — the listing blamed the data for what the filters had done.
    #
    # `"s"` is Ransack's *sort* param, not a filter, and stays out.
    def active_filters
      @active_filters || begin
        filters = query_params.except("s").compact_blank.merge(active_simple_filters)
        filters[search_field_name] = search_value if search_enabled? && search_value.present?
        filters
      end
    end

    # Get the available filter attributes defined via filter_attribute DSL.
    # Used by Filters component for rendering the filter UI.
    #
    # Entries declared with `advanced: false` are excluded. `label:`/`options:`
    # given as zero-arity procs are resolved here with instance_exec, so they
    # can use instance context — most importantly `scope`, the (typically
    # policy-scoped) relation the controller passed in.
    #
    # Override this method for full control; the Filters component consumes
    # whatever it returns.
    #
    # @return [Array<Hash>] Array of attribute definitions with :key, :type, :label, :options
    def available_attributes
      @available_attributes ||=
        self.class.filter_attributes.reject { |attr| attr[:advanced] == false }.map do |attr|
          {
            key: attr[:key],
            type: attr[:type],
            label: resolve_definition_value(attr[:label]) || attr[:key].to_s.humanize,
            options: resolve_definition_value(attr[:options]) || []
          }
        end
    end

    def query_params
      @query_params ||= non_date_range_attribute_names.index_with do |attr_name|
        (value = send(attr_name.to_sym)).is_a?(Array) ? value.compact_blank.presence : value
      end
    end

    def result(options = {})
      @result ||= begin
        relation = ransack_search.result(**options)

        date_range_attributes.each do |date_range_attr|
          value = if respond_to?(date_range_attr)
                    send(date_range_attr)
          else
                    current_simple_filter_value(date_range_attr, nil)
          end

          # Manually cast if it's a string from params
          if value.is_a?(String)
            value = Bali::Types::DateRangeValue.new.cast(value)
          end

          next if value.blank?

          relation = relation.where(date_range_attr => value)
        end

        relation
      end
    end

    def ransack_search
      @ransack_search ||= scope.ransack(ransack_params)
    end

    # Build params hash for Ransack including groupings and search
    def ransack_params
      params = query_params.dup

      # Add groupings for Filters complex conditions
      params[:g] = @groupings if @groupings.present?
      params[:m] = @combinator if @combinator.present?

      # Add quick search parameter
      params[search_field_name] = @search_value if search_enabled? && @search_value.present?

      # Add simple filter parameters
      add_simple_filter_params(params) if simple_filters_enabled?

      # Group-first ordering (sort-within-groups) when grouping is active
      apply_group_by_ordering(params)

      # Último paso y sobre una copia: el estado que se RENDERIZA (filter_groups, las pills,
      # el payload de una vista guardada, la caché de persistencia) sigue hablando en
      # etiquetas, que es lo que trae el `<option value>`. Ver EnumCasting.
      cast_enum_labels(params)
    end

    private

    # Resolve a DSL value that may be callable. Zero-arity procs run under
    # instance_exec so they can reference the form instance (e.g. `scope`);
    # other callables are invoked as-is.
    def resolve_definition_value(value)
      return value unless value.respond_to?(:call)

      value.is_a?(Proc) && value.arity.zero? ? instance_exec(&value) : value.call
    end

    def non_date_range_attribute_names
      attribute_names - date_range_attributes
    end

    # Extract Ransack groupings from params.
    # Groupings format: q[g][0][field_operator]=value, q[g][0][m]=or/and
    #
    # Safety: to_unsafe_h is required because Ransack expects a plain nested hash
    # for its grouping structure. Ransack performs its own attribute authorization
    # via `ransackable_attributes` / `ransackable_associations` on the model,
    # so arbitrary keys are rejected at the Ransack layer, not here.
    #
    # Cada grupo tiene que ser un hash y `g` puede llegar de cualquier forma: `q[g][]` (la
    # forma de ARRAY, que Ransack acepta y Bali no emite) reventaba con un NoMethodError sobre
    # `to_unsafe_h`, y un grupo escalar (`q[g][0]=x`) llegaba entero hasta Ransack para reventar
    # ahí — un 500 en cualquier index desde una URL a mano. Se normaliza a la forma indexada
    # que habla el resto de Bali (filter_groups, el payload de una vista guardada, EnumCasting),
    # así que la forma de array también PASA por la traducción de enums en vez de esquivarla en
    # silencio y devolver los registros contrarios.
    def extract_groupings(q_params)
      groupings = q_params[:g]
      return nil if groupings.blank?

      groups = unwrap_params(groupings)
      groups = groups.each_with_index.to_h { |group, index| [ index.to_s, group ] } if groups.is_a?(Array)
      return nil unless groups.is_a?(Hash)

      groups.transform_values { |group| unwrap_params(group) }
            .select { |_index, group| group.is_a?(Hash) }.presence
    end

    def unwrap_params(value)
      value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value
    end

    # Persist or restore complete filter state including groupings, combinator, and search.
    # Returns [attributes, groupings, combinator, search_value] tuple.
    #
    # Behavior depends on @persist_enabled:
    # - Always saves filters when user submits new ones (so they're available if user enables later)
    # - Only restores filters when @persist_enabled is true
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # `force_write:` — un saved view recién aplicado SIEMPRE cuenta como "filtros recién
    # enviados", incluso cuando su payload resulta en un estado vacío (una vista "ver todo").
    # Sin esto, `has_filter_params` no distingue "no vino nada" de "vino una vista vacía" y
    # con `persist_enabled` cae al branch de restaurar — la caché vieja pisa la vista aplicada.
    def fetch_stored_filter_state(attributes, groupings, combinator, search_value, force_write: false)
      return [ attributes, groupings, combinator, search_value ] unless Object.const_defined?("Rails")

      has_filter_params = force_write || attributes.present? || groupings.present? || search_value.present?

      if has_filter_params
        # User submitted new filters → always save complete state. `group_by` viaja con el
        # resto: sin él, volver al listado restauraba los filtros pero perdía la agrupación
        # (y una vista guardada que agrupa dejaba de reconocerse activa).
        Rails.cache.write(cache_key, {
                            attributes: attributes.to_h,
                            groupings: groupings,
                            combinator: combinator,
                            search_value: search_value,
                            group_by: @group_by
                          })
        [ attributes, groupings, combinator, search_value ]
      elsif @clear_filters
        # User clicked "Clear all" → delete stored filters
        Rails.cache.delete(cache_key)
        [ {}, nil, nil, nil ]
      elsif @clear_search
        # User clicked search clear button → clear just the search from storage. Con la
        # persistencia apagada NO se restaura nada: el usuario pidió explícitamente que el
        # server no le devuelva estado, y limpiar la búsqueda no puede ser la puerta trasera
        # por la que reaparecen filtros que la URL ya no describe.
        stored = @persist_enabled ? Rails.cache.fetch(cache_key) : nil
        if stored.is_a?(Hash)
          Rails.cache.write(cache_key, stored.merge(search_value: nil))
          [ stored[:attributes] || {}, stored[:groupings], stored[:combinator], nil ]
        else
          [ {}, nil, nil, nil ]
        end
      elsif @persist_enabled
        # No filters in URL and persistence enabled → restore from cache
        stored = normalize_stored_state(Rails.cache.fetch(cache_key))
        if @group_by_requested
          # La URL manda, igual que con una vista guardada (ver #apply_saved_view_state).
          # Elegir una agrupación llega SOLO como `?group_by=` —los filtros viven en la caché,
          # así que la URL no los lleva y este branch es el que corre—, y restaurar acá pisaba
          # el click recién hecho con la agrupación vieja: el control no hacía nada, y el
          # viaje tarjetas↔tabla perdía la agrupación en el camino. Se GUARDA además de
          # renderizarse: sin escribirla, el mismo render salía bien y el próximo request sin
          # el param resucitaba la agrupación vieja — el mismo síntoma, corrido un request.
          Rails.cache.write(cache_key, stored.merge(group_by: @group_by))
        elsif stored.key?(:group_by)
          @group_by = resolve_group_by(stored[:group_by])
        end
        [
          stored[:attributes] || {},
          stored[:groupings],
          stored[:combinator],
          stored[:search_value]
        ]
      else
        # Persistence not enabled → don't restore, return empty
        [ {}, nil, nil, nil ]
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # Formato viejo de la caché: solo los atributos, sin las llaves del estado completo. Se
    # normaliza en la entrada para que el resto del branch hable una sola forma — restaurar y
    # volver a escribir tienen que ver el MISMO hash o la caché termina contando otra historia.
    def normalize_stored_state(stored)
      return stored if stored.is_a?(Hash) && stored[:attributes]

      { attributes: stored || {} }
    end

    def array_predicates
      %w[_any _all _not_in _in]
    end
  end
end
