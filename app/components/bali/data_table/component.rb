# frozen_string_literal: true

module Bali
  module DataTable
    class Component < ApplicationViewComponent
      SUMMARY_POSITIONS = %i[top bottom].freeze

      attr_reader :pagy

      renders_one :custom_pagy_nav
      renders_one :actions_panel, ->(
        export_formats: [],
        display_mode_param_name: :data_display_mode,
        grid_display_mode_enabled: false
      ) do
        ActionsPanel::Component.new(
          filter_form: @filter_form,
          url: @url,
          display_mode: @display_mode,
          grid_display_mode_enabled: grid_display_mode_enabled,
          export_formats: export_formats,
          display_mode_param_name: display_mode_param_name
        )
      end

      # Filters panel using Filters component.
      #
      # When a filter_form is provided to DataTable, everything is automatically
      # populated from the form: available_attributes, filter_groups, and search config.
      #
      # @param available_attributes [Array<Hash>] Filterable attributes
      #   (auto-populated from filter_form if not provided)
      # @param filter_groups [Array<Hash>] Initial filter state
      #   (auto-populated from filter_form if not provided)
      # @param search [Hash] Quick search configuration
      #   (auto-populated from filter_form if not provided)
      #   - :fields [Array<Symbol>] Fields to search (e.g., [:name, :description])
      #   - :value [String] Current search value from URL params
      #   - :placeholder [String] Placeholder text for search input
      # @param apply_mode [Symbol] :batch (default) or :live
      # @param popover [Boolean] Show filters in popover (default: true)
      #
      # @example Minimal usage (everything auto-configured from FilterForm)
      #   data_table.with_filters_panel
      #
      # @example Override search placeholder
      #   data_table.with_filters_panel(search: { placeholder: 'Search movies...' })
      #
      # @example Full control
      #   data_table.with_filters_panel(
      #     available_attributes: [{ key: :name, type: :text }, ...],
      #     filter_groups: @filter_form.filter_groups,
      #     search: { fields: [:name], value: '...', placeholder: '...' }
      #   )
      renders_one :filters_panel, ->(available_attributes: nil, search: nil, **options) do
        # Auto-populate from filter_form if not explicitly provided
        resolved_attributes = available_attributes || @filter_form&.available_attributes || []

        # Auto-populate filter_groups from filter_form unless explicitly provided
        if !options.key?(:filter_groups) && @filter_form.respond_to?(:filter_groups)
          options[:filter_groups] = @filter_form&.filter_groups
        end

        # Auto-populate storage_id from filter_form unless explicitly provided
        options[:storage_id] ||= @filter_form&.storage_id if @filter_form.respond_to?(:storage_id)

        # Auto-populate persist_enabled from filter_form unless explicitly provided
        if !options.key?(:persist_enabled) && @filter_form.respond_to?(:persist_enabled?)
          options[:persist_enabled] = @filter_form.persist_enabled?
        end

        # Auto-populate the APPLIED combinator (nil when the state carried no `q[m]`), so the
        # panel re-emits what the user chose instead of its own `:and` default — re-emitting
        # the default flipped an applied OR to AND on the next round-trip.
        if !options.key?(:combinator) && @filter_form.respond_to?(:applied_combinator)
          options[:combinator] = @filter_form.applied_combinator
        end

        # Preserve an active group_by across the GET filter submit (round-trip). Explicit
        # preserved_params MERGE with it instead of replacing it: a host preserving its own
        # params should not silently drop the grouping on every filter/search submit.
        options[:preserved_params] = group_by_preserved_params.merge(options[:preserved_params] || {})

        # Auto-populate search config from filter_form, merging with explicit overrides
        filter_form_search = if @filter_form && @filter_form.respond_to?(:search_config)
                               @filter_form.search_config
        end
        resolved_search = if filter_form_search && search
                            # Merge: filter_form provides base, explicit search overrides
                            filter_form_search.merge(search)
        else
                            search || filter_form_search
        end

        Filters::Component.new(
          url: @url,
          available_attributes: resolved_attributes,
          search: resolved_search,
          **options
        )
      end

      # Simple inline filters (alternative to filters_panel).
      # Use this for CRUD views that only need 2-4 dropdown filters without
      # AND/OR groupings, popovers, or badges.
      #
      # Mutually exclusive with filters_panel - use one or the other.
      #
      # @param filters [Array<Hash>] Filter definitions (auto-populated from filter_form)
      #   Each filter hash should have: :attribute, :collection, :blank, :label, :value, :default
      #
      # @example Minimal (auto-configured from FilterForm)
      #   data_table.with_simple_filters
      #
      # @example With explicit filters
      #   data_table.with_simple_filters(filters: [
      #     { attribute: :status, collection: [["Active", "active"]], blank: "All" }
      #   ])
      renders_one :simple_filters, ->(filters: nil, search: nil, storage_id: nil, persist_enabled: nil) do
        resolved_filters = filters || @filter_form&.simple_filters_config || []
        resolved_search = search || @filter_form&.simple_search_config
        filters_active = @filter_form&.simple_filters_active? || false
        search_active = resolved_search&.dig(:value).present?

        # Auto-populate storage_id from filter_form unless explicitly provided
        storage_id ||= @filter_form&.storage_id if @filter_form.respond_to?(:storage_id)

        # Auto-populate persist_enabled from filter_form unless explicitly provided
        if persist_enabled.nil? && @filter_form.respond_to?(:persist_enabled?)
          persist_enabled = @filter_form.persist_enabled?
        end

        SimpleFilters::Component.new(
          url: @url,
          filters: resolved_filters,
          show_clear: filters_active || search_active,
          search: resolved_search,
          storage_id: storage_id,
          persist_enabled: persist_enabled || false,
          preserved_params: group_by_preserved_params
        )
      end

      renders_one :summary

      class DuplicateContent < StandardError; end

      DUPLICATE_CONTENT_MESSAGE = "DataTable renderiza UN solo slot de contenido " \
        "(with_table / with_grid / with_content). Para alternar entre modos, elige " \
        "cuál declaras con un if sobre display_mode."

      # Banda de contenido. La SUPERFICIE la decide el slot, no el host: `with_table` la
      # trae (una tabla necesita fondo propio), `with_grid` no (las tarjetas YA son la
      # superficie). El slot no puede llamarse `content` —ViewComponent lo reserva—, de
      # ahí el nombre interno y el alias público `with_content`.
      #
      # @param surface [Boolean] Envolver el contenido en Bali::Card (default: true)
      # @param scroll [Boolean] Envolver en el wrapper de scroll horizontal (default: false)
      # @param card_options [Hash] Opciones de Bali::Card (style:, class:, shadow:, body_class:)
      renders_one :content_band, ->(surface: true, scroll: false, **card_options, &block) do
        body = if block.nil?
                 "".html_safe
        elsif scroll
                 tag.div(class: content_scroll_classes, &block)
        else
                 block.call
        end

        # Devolver SIEMPRE un String: con nil ViewComponent tira el contenido en silencio,
        # y devolviendo la Card ella recibiría el bloque original, sin el wrapper de scroll.
        surface ? render(Bali::Card::Component.new(**card_options)) { body } : body
      end

      # Slot for right-aligned toolbar buttons (column selector, export, etc.)
      renders_many :toolbar_buttons

      # Built-in column selector with declarative API
      # @param persist [Boolean] Guardar la visibilidad por dispositivo (localStorage).
      #   Se ignora cuando el listado no tiene un id estable (ver #id).
      # @param button_label [String] Label for the dropdown button (i18n default)
      # @param button_icon [String] Icon name
      # @yield [column_selector] Block to define columns
      renders_one :column_selector, ->(persist: true, **opts, &block) do
        component = ColumnSelector::Component.new(listing_id: id, persist: persist && stable_id?, **opts)
        block&.call(component)
        # Una vista guardada aplicada MANDA: sus columnas visibles pisan los defaults
        # declarados por columna, y el selector marca server_state para que el JS no
        # restaure localStorage encima del estado de la vista.
        if @filter_form.respond_to?(:saved_view_columns) && (view_columns = @filter_form.saved_view_columns)
          component.apply_visible_columns(view_columns)
        end
        component
      end

      # Dropdown "Vistas" (B2): combinaciones de filtros guardadas CON NOMBRE. Solo pinta
      # cuando el filter_form trae `saved_views_store`. `url:` es la base RESTful para
      # crear/renombrar/borrar (POST url, PATCH/DELETE url/:id); si se omite, apunta a las
      # rutas del PROPIO engine (requiere montarlo y que el form tenga `storage_id` — sin
      # storage_id no hay URL default y el dropdown no pinta). La identidad del listado
      # (ver #id) conecta con el column selector para guardar las columnas visibles dentro
      # de la vista; `default_views:` son atajos estáticos {name:, url:} ("Sugeridas").
      renders_one :saved_views, ->(url: nil, default_views: nil) do
        SavedViews::Component.new(filter_form: @filter_form, url: url || default_saved_views_url,
                                  base_url: @url, listing_id: id, default_views: default_views)
      end

      # Built-in export dropdown with format options
      # @param formats [Array<Symbol>] Export formats (e.g., [:csv, :excel, :pdf])
      # @param url [String] Base URL for export (required in production)
      # @param button_label [String] Label for the dropdown button (i18n default)
      # @param button_icon [String] Icon name
      renders_one :export, ->(formats: %i[csv excel pdf], url: nil, **options) do
        Export::Component.new(formats: formats, url: url, **options)
      end

      # @param url [String] Base URL for filtering/sorting links
      # @param filter_form [Bali::FilterForm] Optional filter form for Ransack integration
      # @param pagy [Pagy] Optional Pagy object for pagination
      # @param show_summary [Boolean] Show summary (default: true when pagy present)
      # @param summary_position [Symbol] :bottom (default) or :top
      # @param item_name [String] Name for items in summary (i18n default)
      # @param table_class [String] CSS class for the content scroll wrapper
      # @param display_mode [Symbol] Modo de visualización declarado por el host. NO elige
      #   slot (hay uno solo): el host decide qué contenido declara.
      # @param id [String] Identidad del listado. Es a la vez el id del contenedor, el
      #   target de querySelector del selector de columnas (`#<id> table`) y la llave de
      #   localStorage de sus columnas: UN solo nombre para todo lo que el listado persiste.
      def initialize(url:, filter_form: nil, pagy: nil, **options)
        @filter_form = filter_form
        @url = url
        @pagy = pagy
        @show_summary = options.fetch(:show_summary) { pagy.present? }
        @summary_position = validate_summary_position(options[:summary_position])
        @item_name = options[:item_name]
        @table_wrapper_class = options[:table_class]
        @display_mode = (options[:display_mode] || :table).to_sym
        @content_declared = false
        @listing_id, @stable_id = resolve_listing_id(options[:id])
      end

      # Una sola banda de contenido: `with_table`/`with_grid` son azúcar sobre ella.
      # `display_mode` YA NO elige entre slots — el host decide qué renderiza.
      def with_content(surface: true, scroll: false, **options, &block)
        raise DuplicateContent, DUPLICATE_CONTENT_MESSAGE if @content_declared

        @content_declared = true
        with_content_band(surface: surface, scroll: scroll, **options, &block)
      end

      # Una tabla trae superficie y scroll horizontal.
      def with_table(**options, &block)
        with_content(surface: true, scroll: true, **options, &block)
      end

      # Un grid de tarjetas NO lleva superficie: las tarjetas ya son la superficie.
      def with_grid(**options, &block)
        with_content(surface: false, **options, &block)
      end

      # Clases del wrapper de scroll horizontal (solo cuando el slot lo pide).
      def content_scroll_classes
        @table_wrapper_class || "overflow-x-auto"
      end

      TOOLBAR_CLASSES = "flex items-center gap-2 sm:gap-4 mb-4"

      # La toolbar va SIN superficie: es la MISMA fila en todos los modos de visualización
      # y la superficie la trae el contenido.
      def toolbar_classes
        TOOLBAR_CLASSES
      end

      def id
        @listing_id
      end

      # ¿El id sobrevive al próximo render? Con el hex aleatorio no, y una llave que cambia
      # en cada visita jamás va a restaurar nada: la persistencia por dispositivo se apaga
      # sola en vez de escribir basura que nadie puede leer de vuelta.
      def stable_id?
        @stable_id
      end

      # Auto-generated summary text from Pagy using I18n
      def default_summary_text
        return "" unless @pagy

        I18n.t(
          "view_components.bali.data_table.summary",
          from: @pagy.from,
          to: @pagy.to,
          count: @pagy.count,
          item_name: item_name
        )
      end

      def show_summary_top?
        @show_summary && @summary_position == :top && !summary?
      end

      def show_summary_bottom?
        @show_summary && @summary_position == :bottom && !summary?
      end

      def show_footer?
        @pagy || summary? || show_summary_bottom?
      end

      def show_toolbar?
        filters_panel? || simple_filters? || group_by_control? || toolbar_buttons? ||
          column_selector? || export? || actions_panel? || saved_views?
      end

      # Whether the "Agrupar por" control should render — true when the filter
      # form declares any group_by attribute. Auto-rendered (no explicit slot).
      def group_by_control?
        @filter_form.respond_to?(:group_by_options) && @filter_form.group_by_options.present?
      end

      # The auto-configured group_by control component.
      def group_by_control
        @group_by_control ||= GroupByControl::Component.new(
          url: @url,
          filter_form: @filter_form,
          current_params: safe_query_parameters
        )
      end

      def show_toolbar_right?
        saved_views? || toolbar_buttons? || column_selector? || export? || actions_panel?
      end

      private

      # [id, estable?]. `FilterForm#id` (scope.cache_key) NO sirve como identidad: trae una
      # diagonal —'movies/query-abc'— que rompe el querySelector, y además dos listados
      # sobre el mismo scope base caen en el mismo valor (era el caso de /movies y
      # /admin/movies, que terminaban compartiendo la memoria de columnas).
      def resolve_listing_id(explicit)
        given = sanitize_listing_id(explicit) || sanitize_listing_id(form_storage_id)
        return [ given, true ] if given

        [ "data-table-#{SecureRandom.hex(4)}", false ]
      end

      # Slug usable como identificador CSS: sin "#" inicial, sin caracteres inválidos y sin
      # empezar con dígito — `#123 table` hace que querySelector lance SyntaxError. No se
      # hace downcase a propósito: el matching de `#id` en HTML es case-sensitive.
      def sanitize_listing_id(value)
        slug = value.to_s.delete_prefix("#").gsub(/[^A-Za-z0-9_-]+/, "-").gsub(/\A-+|-+\z/, "")
        return if slug.blank?

        slug.match?(/\A\d/) ? "listing-#{slug}" : slug
      end

      def form_storage_id
        @filter_form.storage_id if @filter_form.respond_to?(:storage_id)
      end

      # URL default de las mutaciones de vistas guardadas: las rutas del PROPIO engine
      # (montado en el host). El storage_id viaja en el query string porque el create del
      # engine no tiene otro lugar de dónde sacarlo.
      def default_saved_views_url
        return unless @filter_form.respond_to?(:storage_id) && @filter_form.storage_id.present?

        helpers.bali.saved_views_path(storage_id: @filter_form.storage_id)
      end

      # group_by param to preserve as a hidden field on GET filter forms, so
      # applying filters/search does not drop an active grouping.
      def group_by_preserved_params
        return {} unless @filter_form.respond_to?(:group_by_active?) && @filter_form.group_by_active?

        { "group_by" => @filter_form.group_by.to_s }
      end

      # Current request query params (to preserve in group_by control links).
      # Falls back to {} when there is no request context.
      def safe_query_parameters
        helpers.request.query_parameters.to_h
      rescue StandardError
        {}
      end

      def item_name
        @item_name || I18n.t("view_components.bali.data_table.default_item_name")
      end

      def validate_summary_position(position)
        SUMMARY_POSITIONS.include?(position) ? position : :bottom
      end
    end
  end
end
