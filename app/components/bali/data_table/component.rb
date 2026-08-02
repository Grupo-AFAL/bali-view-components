# frozen_string_literal: true

module Bali
  module DataTable
    class Component < ApplicationViewComponent
      include Bali::DataTable::ToolbarHref

      SUMMARY_POSITIONS = %i[top bottom].freeze

      # La prioridad manda DOS cosas a la vez, y por eso la escala no se puede renumerar
      # mirando una sola: qué SOBREVIVE en un viewport angosto (colapsa lo que quede por
      # debajo de OVERFLOW_THRESHOLD) y, DENTRO de cada grupo, el ORDEN en que se pintan los
      # controles — el JS reordena cada grupo por prioridad al expandir, así que mover un
      # bloque del template no mueve nada en el navegador.
      #
      # El orden ENTRE grupos lo fija la plantilla (ver #show_toolbar_left? y sus hermanos),
      # que es lo único que deja al view switch sobrevivir a todo y aun así verse último.
      #
      # Los números bajan en el mismo orden en que se leen los controles de la fila: eso es
      # lo que mantiene el orden de lectura del ⋯ igual al de la toolbar (ver
      # `collapsibleItems` en el controlador). `search` y `filters` son EL MISMO nodo
      # (Bali::Filters pinta el input de búsqueda y el botón de filtros juntos), por eso hay
      # una sola entrada. Se guarda como escala y no como lista ordenada para que sumar un
      # segundo umbral sea un cambio de una línea.
      OVERFLOW_PRIORITIES = {
        filters: 70,
        view_switch: 50,
        group_by: 40,
        column_selector: 35,
        saved_views: 30,
        filter_persistence: 25,
        toolbar_buttons: 10
      }.freeze

      # Colapsa lo que esté POR DEBAJO del umbral. Con un solo breakpoint la escala se
      # reduce a este corte.
      OVERFLOW_THRESHOLD = 50

      attr_reader :pagy

      renders_one :custom_pagy_nav

      # Barra contextual de selección: REEMPLAZA la fila de la toolbar mientras haya
      # selección y la restaura al limpiar. El controlador Stimulus vive en el CONTENEDOR
      # del DataTable (ver #container_attributes) y no en este slot: dos controladores
      # `bulk-actions` anidados se reparten los targets y la barra no vería las filas.
      #
      # El bloque NO se corre acá, a diferencia de column_selector/view_switch: `with_action`
      # es un slot de ViewComponent de verdad, y leer un slot ya fuerza la evaluación del
      # bloque una vez (Slotable#__vc_get_slot llama a `content`). Correrlo además acá lo
      # ejecuta DOS veces y duplica cada acción, en silencio. Los otros dos slots no tienen
      # el problema porque su `with_*` es un método plano sobre un array.
      #
      # @param options [Hash] Opciones de Bali::BulkActions (class:, data:)
      # @yield [bulk_actions] Bloque para declarar las acciones con `with_action`
      #
      # `**options` va PRIMERO: lo que el componente posee no se puede pisar desde el host.
      # Splateado al final, un `standalone: true` del host anidaba un segundo controlador y
      # rompía en silencio la invariante que este comentario acaba de documentar.
      renders_one :bulk_actions, ->(**options) do
        Bali::BulkActions::Component.new(**options, variant: :toolbar, standalone: false)
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

        # Preserve the listing state (grouping + display mode) across the GET filter submit
        # (round-trip). Explicit preserved_params MERGE with it instead of replacing it: a
        # host preserving its own params should not silently drop the grouping on every
        # filter/search submit.
        options[:preserved_params] = preserved_state_params.merge(options[:preserved_params] || {})

        # El marcador se pinta UNA sola vez, y como control propio de la toolbar (ver
        # #filter_persistence_control): dos controladores `filter-persistence` sobre el mismo
        # storage_id se pisan el localStorage y la cookie. El panel igual recibe
        # `persist_enabled` — de ahí sale su leyenda "Auto-guardado".
        #
        # Asignación y no `||=`: el splat `**options` va al FINAL del constructor, así que un
        # `persistence_toggle: true` del host ganaría y anidaría el segundo controlador.
        capture_persistence(options[:storage_id], options[:persist_enabled])
        options[:persistence_toggle] = false

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

        # Mismo motivo que en `filters_panel`: el marcador sale del form y lo pinta la toolbar.
        capture_persistence(storage_id, persist_enabled)

        SimpleFilters::Component.new(
          url: @url,
          filters: resolved_filters,
          show_clear: filters_active || search_active,
          search: resolved_search,
          storage_id: storage_id,
          persist_enabled: persist_enabled || false,
          persistence_toggle: false,
          preserved_params: preserved_state_params
        )
      end

      renders_one :summary

      class DuplicateContent < StandardError; end

      DUPLICATE_CONTENT_MESSAGE = "DataTable renderiza UN solo slot de contenido " \
        "(with_table / with_grid / with_content). Para alternar entre modos, elige " \
        "cuál declaras con un if sobre display_mode."

      VIEW_PARAM_MISMATCH_MESSAGE = "El DataTable lee el modo de visualización de `%s` y el " \
        "FilterForm de `%s`. Desincronizados, la agrupación se suspende mirando un param que " \
        "el view switch nunca escribe (o se sigue aplicando en tarjetas). Pasá el mismo " \
        "`view_param:` a los dos."

      DISPLAY_MODE_MISMATCH_MESSAGE = "Este listado renderiza `%s`, que no está entre los " \
        "modos que aplican agrupación (%s), pero su FilterForm nunca vio un modo: sin " \
        "`?view=` en la URL da por hecho que aplica y ordena las filas por el grupo sin que " \
        "nada en pantalla lo explique. Pasale el modo al form: " \
        "`Bali::FilterForm.new(..., display_mode: params[:view] || :%s)`."

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
        # `**opts` primero: la identidad del listado la resuelve el DataTable y pisarla desde
        # el host apuntaba el selector a un contenedor distinto del de las vistas guardadas.
        component = ColumnSelector::Component.new(**opts, listing_id: id, persist: persist && stable_id?)
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
                                  base_url: saved_views_base_url, listing_id: id,
                                  default_views: default_views)
      end

      # Segmented control de vistas (tabla / tarjetas / lo que el host defina). A diferencia
      # de Bali::ViewSwitch acá NO se pasa `href:`: cada vista declara su `value:` y el
      # DataTable arma el link preservando el query string. `href:` sigue aceptado por vista
      # para un modo que vive en otra ruta.
      #
      # @param aria_label [String] Label accesible del grupo (default i18n)
      # @param options [Hash] Opciones de Bali::ViewSwitch (size:, icon_only:, class:)
      # @yield [view_switch] Bloque para declarar las vistas con `with_view`
      renders_one :view_switch, ->(aria_label: nil, **options, &block) do
        # El switch NO se colapsa al ⋯ (prioridad 50 = umbral): se ENCOGE. `:responsive`
        # esconde el texto bajo sm dejando title/aria-label, así que el botón nunca queda
        # sin nombre accesible — que es lo que pasaría escondiendo el label a mano.
        options[:icon_only] = :responsive unless options.key?(:icon_only)

        # `**options` primero: la URL, el param y el modo actual los resuelve el DataTable —
        # pisarlos desde el host daba links apuntando a un param y hidden fields a otro.
        component = ViewSwitchControl::Component.new(
          **options,
          url: @url,
          current_params: request_query_params,
          param: @view_param,
          current: requested_display_mode,
          aria_label: aria_label
        )
        block&.call(component)
        # El gateo de display_mode necesita las vistas YA declaradas, y eso solo pasa
        # después de correr el bloque del host (ver #display_mode).
        @view_switch_control = component
        component
      end

      # @param url [String] Base URL for filtering/sorting links. También es la base de los
      #   links de página cuando el Pagy no puede armar los suyos (ver #pagination_url)
      # @param filter_form [Bali::FilterForm] Optional filter form for Ransack integration
      # @param pagy [Pagy] Optional Pagy object for pagination
      # @param show_summary [Boolean] Show summary (default: true when pagy present)
      # @param summary_position [Symbol] :bottom (default) or :top
      # @param item_name [String] Name for items in summary (i18n default)
      # @param table_class [String] CSS class for the content scroll wrapper
      # @param display_mode [Symbol] Modo de visualización pedido por el host (típicamente
      #   `params[:view]`). NO elige slot (hay uno solo): el host decide qué contenido
      #   declara, leyendo el valor YA validado en #display_mode.
      # @param view_param [Symbol] Param de la URL que lleva la vista (default :view)
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
        # `.to_s` primero: esto suele llegar directo de `params[:view]`, y un param anidado
        # (`?view[]=x`) no responde a `to_sym`. El valor se valida después contra las vistas
        # declaradas (ver #display_mode); acá solo se normaliza sin reventar.
        @display_mode = (options[:display_mode].to_s.presence || "table").to_sym
        @view_param = (options[:view_param] || Bali::FilterForm::DEFAULT_VIEW_PARAM).to_sym
        # Solo un host que DECLARÓ el modo tiene un `view` que preservar; el default no se
        # escribe en la URL de un listado que ni siquiera tiene view switch.
        @display_mode_declared = options[:display_mode].present?
        @content_declared = false
        @listing_id, @stable_id = resolve_listing_id(options[:id])
        validate_view_param!
      end

      # Modo de visualización YA validado contra las vistas declaradas: un `?view=`
      # desconocido cae a la primera vista en vez de dejar el contenido vacío (misma
      # frontera que FilterForm#resolve_group_by). El host lo lee dentro del bloque para
      # elegir qué contenido declara — por eso se resuelve tarde y no en `initialize`: las
      # vistas se declaran DESPUÉS de construir el componente.
      def display_mode
        mode = @view_switch_control ? @view_switch_control.current_value : requested_display_mode
        validate_display_mode!(mode)
        mode
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

      # `min-h-8` es el alto de un control `sm` de daisyUI, que es el que esta fila ya tenía
      # por su contenido. Se declara EXPLÍCITO porque la fila contextual de selección lo
      # reemplaza en este mismo hueco (`BulkActions::Component::TOOLBAR_MIN_HEIGHT`): con el
      # alto como accidente del contenido, cualquier cambio ahí reintroduce el salto de layout.
      TOOLBAR_CLASSES = "flex items-center gap-2 sm:gap-4 min-h-8 mb-4"

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

      # La MISMA frase que pinta el footer, del mismo sitio: el summary de arriba y el de
      # abajo son la misma cuenta, y tenerlos derivados por separado fue lo que dejó dos
      # claves i18n para una sola oración.
      def default_summary_text
        return "" unless @pagy

        pagy_adapter.summary(@item_name)
      end

      def show_summary_top?
        summary_position?(:top) && summarizable?
      end

      def show_summary_bottom?
        summary_position?(:bottom) && summarizable?
      end

      # El footer lo arma `PaginationFooter`, que decide solo si tiene algo que dibujar;
      # acá solo se le pasa lo que este listado quiere de él.
      #
      # `divider:` y no el espaciado por `class:`: mandarlo por ahí dejaba el `py-4` del
      # footer Y el `pt-4` del listado sobre el mismo elemento, y eso le sumaba al pie de la
      # tabla 16px de padding inferior que nunca tuvo. Tailwind resuelve ese par por orden
      # de hoja de estilos, no por el orden en que escribes las clases.
      def pagination_footer
        Bali::PaginationFooter::Component.new(
          pagy: @pagy,
          item_name: @item_name,
          show_summary: show_summary_bottom?,
          url: pagination_url,
          divider: true
        )
      end

      # Contenido YA renderizado de un control declarativo, o nil si el control decidió no
      # pintar. Declarar el slot NO es lo mismo que pintar: `with_saved_views` sobre un form
      # sin store deja `render?` en false, y mirar solo el predicado del slot dejaba un
      # envoltorio vacío que en un teléfono terminaba destapando un ⋯ que abría un menú
      # vacío — justo lo que el gate de #overflow_menu? existe para evitar.
      #
      # Se memoiza porque el template lo vuelve a leer (ViewComponent::Slot#to_s ya memoiza,
      # pero acá además se cachea el `nil`).
      def control_content(key)
        @control_contents ||= {}
        return @control_contents[key] if @control_contents.key?(key)

        @control_contents[key] = (public_send(key).to_s.presence if public_send(:"#{key}?"))
      end

      def show_toolbar?
        declared_toolbar_controls.any?
      end

      # El contenedor es quien lleva el controlador de selección: tiene que envolver a la
      # vez a la barra contextual y a las filas de la tabla.
      def container_attributes
        attrs = { id: id, class: "data-table-component" }
        bulk_actions? ? prepend_controller(attrs, "bulk-actions") : attrs
      end

      # La fila de la toolbar lleva el controlador de overflow, y se marca además para que
      # el de selección pueda esconderla mientras la barra contextual ocupa su lugar.
      def toolbar_attributes
        attrs = prepend_controller({ class: toolbar_classes }, "toolbar-overflow")
        # El umbral se EMITE: el gate del ⋯ y el corte que aplica el JS son el mismo número,
        # y con dos defaults independientes moverlo de un lado dejaba al otro pintando un
        # menú que nunca se llena. El default del controlador cubre solo markup a mano.
        prepend_values(attrs, "toolbar-overflow", threshold: OVERFLOW_THRESHOLD)
        return attrs unless bulk_actions?

        attrs[:data][:bulk_actions_target] = "toolbar"
        attrs
      end

      # Contenedor hogar de un grupo funcional: al expandir, cada control vuelve al grupo
      # que declara acá. INVARIANTE: un grupo solo puede tener hijos `item` — el JS reordena
      # appendeando por prioridad y un hijo sin prioridad terminaría empujado al final.
      def overflow_group_attributes(group, css_class:)
        {
          class: css_class,
          data: { toolbar_overflow_target: "group", toolbar_overflow_group: group }
        }
      end

      # Envoltorio de un control: a qué grupo vuelve y con qué prioridad (ver
      # OVERFLOW_PRIORITIES). Es el nodo que el JS MUEVE, nunca copia.
      def overflow_item_attributes(key, group:, css_class: nil)
        {
          class: css_class,
          data: {
            toolbar_overflow_target: "item",
            toolbar_overflow_group: group,
            toolbar_overflow_priority: overflow_priority(key)
          }
        }
      end

      # La barrita NO es un control: sin prioridad y sin ser `item`, `collapsibleItems` no la
      # puede ver y nunca viaja al ⋯. Declara a quién separa POR NOMBRE en vez de mirar a sus
      # hermanos del DOM: con adyacencia, insertar cualquier nodo en el medio rompía la
      # decisión en silencio. `max-sm:hidden` cubre el caso sin JS — bajo el breakpoint no
      # queda nadie a su derecha que la sostenga.
      def overflow_separator_attributes(*groups)
        {
          class: "shrink-0 max-sm:hidden",
          data: {
            toolbar_overflow_target: "separator",
            toolbar_overflow_separates: groups.join(" ")
          }
        }
      end

      # El ⋯ no se pinta si no hay nada que colapsar: sin esto, un listado que solo tiene
      # búsqueda mostraría un botón que abre un menú vacío.
      def overflow_menu?
        declared_toolbar_controls.any? { |key| overflow_priority(key) < OVERFLOW_THRESHOLD }
      end

      def overflow_priority(key)
        OVERFLOW_PRIORITIES.fetch(key)
      end

      def overflow_menu_label
        I18n.t("bali_view.data_table.toolbar_overflow.button_label")
      end

      # Whether the "Agrupar por" control should render — true when the filter form declares
      # any group_by attribute AND la agrupación aplica en este modo de visualización.
      # Auto-rendered (no explicit slot).
      #
      # Fuera de la tabla el control se ESCONDE: ofrecer una agrupación que no va a pasar
      # nada es peor que no ofrecerla. La condición la resuelve el FORM
      # (FilterForm#group_by_applies?) y no el componente — re-derivarla acá era la segunda
      # copia de la misma regla, y las dos copias se desalinean. `respond_to?` con fallback a
      # "aplica": un filter_form ajeno no puede perder su control por no conocer la API nueva.
      # El control se pinta SIEMPRE que el form declare agrupaciones. En un modo que no la
      # aplica va inerte (ver #group_by_disabled?) en vez de desaparecer: esconderlo movía la
      # toolbar entera al cambiar de modo y no explicaba nada.
      def group_by_control?
        @filter_form.respond_to?(:group_by_options) && @filter_form.group_by_options.present?
      end

      def group_by_disabled?
        @filter_form.respond_to?(:group_by_applies?) && !@filter_form.group_by_applies?
      end

      # The auto-configured group_by control component.
      def group_by_control
        @group_by_control ||= GroupByControl::Component.new(
          url: @url,
          filter_form: @filter_form,
          current_params: request_query_params,
          disabled: group_by_disabled?
        )
      end

      # El marcador recuerda el estado de los FILTROS: suelto, en un listado sin control de
      # filtros, no significa nada. Se pregunta por el CONTENIDO y no por el predicado del
      # slot porque `SimpleFilters#render?` es false sin filtros ni búsqueda — declarar el
      # slot no es lo mismo que pintar (ver #control_content).
      def filter_persistence_control?
        @persistence_storage_id.present? &&
          (control_content(:filters_panel) || control_content(:simple_filters)).present?
      end

      def filter_persistence_control
        @filter_persistence_control ||= Bali::Filters::PersistenceToggle::Component.new(
          storage_id: @persistence_storage_id, enabled: @persistence_enabled
        )
      end

      # IZQUIERDA el estado del listado y cómo se recuerda; DERECHA cómo se ve. El modo de
      # visualización NO viaja dentro de una vista guardada (no está en PAYLOAD_KEYS), y por
      # eso el view switch es lo único que queda del otro lado.
      #
      # Primer subgrupo de la izquierda: el CONTENIDO de la vista — qué filas y qué columnas.
      def show_toolbar_left?
        (declared_toolbar_controls & %i[filters group_by column_selector]).any?
      end

      # Segundo subgrupo de la izquierda: cómo se RECUERDA ese contenido.
      def show_toolbar_memory?
        (declared_toolbar_controls & %i[saved_views filter_persistence]).any?
      end

      # Los botones del host no caen en ninguno de los tres cubos: grupo propio, entre lo que
      # se recuerda y el borde derecho. Metidos en el grupo de la derecha el JS los ordenaba
      # por prioridad (10 contra 50) y quedaban DESPUÉS del view switch, que es lo único que
      # va pegado al borde.
      def show_toolbar_host?
        declared_toolbar_controls.include?(:toolbar_buttons)
      end

      def show_toolbar_right?
        declared_toolbar_controls.include?(:view_switch)
      end

      # La barrita afirma algo sobre sus dos vecinos ("acá termina qué contiene la vista y
      # empieza cómo se recuerda"): con un solo lado marcaría una frontera contra nada. Bajo
      # el breakpoint la esconde el JS (ver #overflow_separator_attributes).
      def toolbar_separator?
        show_toolbar_left? && show_toolbar_memory?
      end

      private

      # Los valores los RESUELVE el slot (pueden venir del filter_form o explícitos del host),
      # así que se capturan ahí y no se re-derivan acá: re-derivarlos del filter_form dejaba
      # sin marcador a un host que pasa `storage_id:` directo al slot.
      def capture_persistence(storage_id, enabled)
        @persistence_storage_id = storage_id.presence
        @persistence_enabled = !!enabled
      end

      # Qué familias de control PINTAN algo. Es la ÚNICA lista: `overflow_menu?`,
      # `show_toolbar?` y los `show_toolbar_*` de cada grupo se derivan de acá, así que el
      # gate del ⋯ no puede desalinearse de lo que el JS colapsa. Mira el render, no el
      # predicado del slot (ver #control_content).
      def declared_toolbar_controls
        @declared_toolbar_controls ||= begin
          controls = []
          controls << :filters if control_content(:filters_panel) || control_content(:simple_filters)
          controls << :filter_persistence if filter_persistence_control?
          controls << :group_by if group_by_control?
          controls << :view_switch if control_content(:view_switch)
          controls << :saved_views if control_content(:saved_views)
          controls << :column_selector if control_content(:column_selector)
          controls << :toolbar_buttons if toolbar_buttons?
          controls
        end
      end

      # [id, estable?]. `FilterForm#id` (scope.cache_key) NO sirve como identidad: trae una
      # diagonal —'movies/query-abc'— que rompe el querySelector, y además dos listados
      # sobre el mismo scope base caen en el mismo valor (era el caso de /movies y
      # /admin/movies, que terminaban compartiendo la memoria de columnas).
      def resolve_listing_id(explicit)
        given = sanitize_listing_id(explicit) || sanitize_listing_id(form_storage_id)
        return [ given, true ] if given

        [ "data-table-#{SecureRandom.hex(4)}", false ]
      end

      # La MISMA regla que un `.turbo_stream.erb` del host tiene que poder aplicar para
      # apuntar su `turbo_stream.replace`: vive en ListingIdentity, público (ver
      # ListingIdentity.for).
      def sanitize_listing_id(value)
        ListingIdentity.sanitize(value)
      end

      def form_storage_id
        @filter_form.storage_id if @filter_form.respond_to?(:storage_id)
      end

      # El modo pedido, CRUDO: el que declaró el host o, si no declaró ninguno, el que trae
      # la URL. Sin el fallback, un host que arma el view switch y se olvida de
      # `display_mode:` obtiene links que cambian la URL y nunca cambian la vista: el
      # componente ya tiene el query string en la mano (lo usa para armar esos mismos hrefs)
      # y quedarse mirando solo el kwarg era fallar en silencio.
      #
      # Tarde y no en `initialize`: `helpers` todavía no existe antes del render.
      def requested_display_mode
        return @display_mode if @display_mode_declared

        request_query_params[@view_param.to_s].to_s.presence&.to_sym
      end

      # Aplicar una vista guardada no debería sacar al usuario del modo en el que está
      # mirando el listado: el view switch preserva `saved_view` a propósito y la dirección
      # inversa tiene que ser simétrica. Viaja SOLO el modo — arrastrar el query string
      # entero haría que un `group_by` de la URL le gane al que trae el payload de la vista
      # (ver FilterForm#apply_saved_view_state).
      def saved_views_base_url
        view = view_preserved_params
        return @url if view.empty?

        "#{@url}#{@url.to_s.include?('?') ? '&' : '?'}#{view.to_query}"
      end

      # URL default de las mutaciones de vistas guardadas: las rutas del PROPIO engine
      # (montado en el host). El storage_id viaja en el query string porque el create del
      # engine no tiene otro lugar de dónde sacarlo.
      def default_saved_views_url
        return unless @filter_form.respond_to?(:storage_id) && @filter_form.storage_id.present?

        helpers.bali.saved_views_path(storage_id: @filter_form.storage_id)
      end

      # Estado del listado que tiene que sobrevivir a un submit GET de filtros. Los links del
      # view switch mergean el query string entero, pero un submit de filtros lo reconstruye
      # desde `url:` —que el host pasa SIN query string—, así que la agrupación y el modo de
      # visualización tienen que viajar como hidden fields o filtrar estando en tarjetas
      # devuelve al usuario a la tabla.
      def preserved_state_params
        group_by_preserved_params.merge(view_preserved_params).merge(saved_view_origin_params)
      end

      # El ORIGEN viaja; `saved_view` no (sigue en EXCLUDED_PARAMS de Filters, porque APLICA).
      # Sin esto, cambiar un filtro sobre una vista aplicada la volvía anónima y el dropdown
      # solo podía ofrecer "guardar otra".
      def saved_view_origin_params
        origin = @filter_form.try(:saved_view_origin_id)
        origin.present? ? { "view_origin" => origin.to_s } : {}
      end

      # El modo CRUDO, no el gateado: las vistas se declaran después de construir el slot del
      # panel de filtros, así que acá el gateo todavía no se puede resolver. Un valor
      # desconocido es inofensivo — el próximo request lo vuelve a gatear.
      def view_preserved_params
        mode = requested_display_mode
        mode.present? ? { @view_param.to_s => mode.to_s } : {}
      end

      # group_by param to preserve as a hidden field on GET filter forms, so
      # applying filters/search does not drop an active grouping.
      #
      # `group_by_active?` (ESTADO) y NO `group_by_applied?` (APLICACIÓN) a propósito: en
      # tarjetas la agrupación está suspendida pero el param TIENE que seguir viajando — si
      # no, buscar algo estando en tarjetas la borra y volver a la tabla ya no la encuentra.
      def group_by_preserved_params
        return {} unless @filter_form.respond_to?(:group_by_active?) && @filter_form.group_by_active?

        { "group_by" => @filter_form.group_by.to_s }
      end

      # Falla temprano: con los dos params desincronizados no hay NADA visible que lo delate
      # — la tabla se ve igual y la suspensión decide al revés. Solo importa si el listado
      # declara agrupación; sin ella el modo de visualización no cambia ninguna decisión.
      def validate_view_param!
        return unless @filter_form.respond_to?(:view_param) &&
                      @filter_form.respond_to?(:group_by_enabled?) &&
                      @filter_form.group_by_enabled? &&
                      @filter_form.view_param != @view_param

        raise ArgumentError,
              format(VIEW_PARAM_MISMATCH_MESSAGE, @view_param, @filter_form.view_param)
      end

      # El modo se deriva DOS veces —el DataTable lo resuelve contra las vistas declaradas, el
      # form lo lee de la URL— y sin `?view=` las dos derivaciones dicen cosas distintas: el
      # listado pinta la primera vista declarada y el form, viendo nil, da por hecho que
      # aplica. Con las tarjetas declaradas primero eso es la agrupación corriendo sobre
      # tarjetas, que es justo lo que la suspensión existe para evitar.
      #
      # Se valida en el momento en que el modo se CONSUME (el host llama a #display_mode para
      # elegir qué contenido declara) porque las vistas se declaran después de construir el
      # componente. Solo cuando el form no tiene modo propio: con un `?view=` desconocido
      # —que un usuario puede tipear— el form suspende y el listado cae a la primera vista, y
      # eso es un límite conocido, no una config rota que merezca reventar.
      def validate_display_mode!(mode)
        return if @display_mode_validated

        @display_mode_validated = true
        return if mode.nil?
        return unless @filter_form.respond_to?(:group_by_enabled?) && @filter_form.group_by_enabled?
        return unless @filter_form.respond_to?(:display_mode) && @filter_form.display_mode.nil?
        return if @filter_form.group_by_modes.include?(mode)

        raise ArgumentError,
              format(DISPLAY_MODE_MISMATCH_MESSAGE, mode, @filter_form.group_by_modes.join(", "), mode)
      end

      # Base para los links de página, o `nil` para dejar que el Pagy arme los suyos.
      #
      # `nil` cuando el Pagy es linkable —el caso del helper `pagy()`, o sea todo host
      # normal— y eso es deliberado: pasarle una base al `PaginationFooter` la hace GANAR
      # (ver PagyAdapter#page_url, #654), y la `url:` de este listado es la base de filtrado
      # y orden, que el host pasa sin query string (`admin_movies_path`). Reenviarla a
      # ciegas convertía `/movies?q[name_cont]=a&page=1` en `/movies?page=2`: el filtro
      # aplicado se perdía al pasar de página. Con el Pagy en su sitio, Pagy compone la URL
      # desde el request real y el recorte sobrevive, además de respetar sus propias
      # opciones (`root_key:`, `querify:`, `limit_key:`, `absolute:`) que esta base no sabe
      # reproducir.
      #
      # Un Pagy SIN request —`Pagy::Offset.new` a mano, `render_inline`— no puede armar nada
      # y caía en un `?page=2` pelado que borra el query string entero del navegador. Ahí sí
      # hace falta una base, y el listado ya sabe construirla: la MISMA que arman el view
      # switch y "Agrupar por" (`url:` + el query string actual, menos los params de un solo
      # uso, `page` entre ellos). Así los links de página preservan filtros, orden y vista
      # guardada en vez de solo apuntar al path correcto. Hasta ahora el DataTable no
      # reenviaba NADA y ese host no tenía parámetro alguno con el que arreglarlo (#756).
      def pagination_url
        return if @pagy.nil? || pagy_adapter.linkable?

        build_toolbar_href(@url, request_query_params, :page, nil)
      end

      def pagy_adapter
        @pagy_adapter ||= Bali::Pagination::PagyAdapter.new(@pagy)
      end

      def summary_position?(position)
        @show_summary && @summary_position == position && !summary?
      end

      # Cero resultados no tienen rango que describir: "Showing 0-0 of 0 movies" es lo que
      # salía en una búsqueda sin resultados.
      def summarizable?
        @pagy.present? && pagy_adapter.summarizable?
      end

      def validate_summary_position(position)
        SUMMARY_POSITIONS.include?(position) ? position : :bottom
      end
    end
  end
end
