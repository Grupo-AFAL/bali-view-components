# frozen_string_literal: true

module Bali
  module DataTable
    module SimpleFilters
      # SimpleFilters provides inline dropdown filters for DataTable.
      # Unlike the complex Filters component, SimpleFilters renders as a simple
      # row of select dropdowns with a submit button - no popovers, no AND/OR
      # groupings, no operator selection.
      #
      # @example Via DataTable slot (auto-configured from FilterForm)
      #   data_table.with_simple_filters
      #
      # @example With explicit filters
      #   data_table.with_simple_filters(filters: [
      #     { attribute: :status, collection: [...], blank: "All", label: "Status" }
      #   ])
      #
      class Component < ApplicationViewComponent
        include Utils::Url
        include Bali::Filters::PreservedParams
        include Bali::Filters::Persistable

        # Min-width for slim_select dropdowns. Triggers in SimpleFilters are narrow
        # (~13rem), so we let the dropdown grow past the trigger to fit long labels
        # without wrapping.
        SLIM_SELECT_CONTENT_WIDTH = ">240px"

        # @param url [String] Form submission URL
        # @param filters [Array<Hash>] Filter configurations
        # @param show_clear [Boolean] Show clear button
        # @param search [Hash, nil] Search input configuration (see Bali::SearchConfig)
        #   - :fields [Array<Symbol>] Columns to search (e.g., [:name, :email]);
        #     Bali derives the Ransack param name from them
        #   - :value [String, nil] Current search value
        #   - :placeholder [String, nil] Placeholder text
        #   - :label [String, nil] Accessible name for the search input
        #   - :icon [String, nil] Icon rendered as a leading addon
        #   - :width [String, nil] Tailwind width classes (default: "w-48 sm:w-96")
        # @param storage_id [String, nil] Optional storage ID indicating filters can be persisted
        # @param persist_enabled [Boolean] Whether user has opted into filter persistence
        # @param persistence_toggle [Boolean] Render the bookmark toggle inline (default: true).
        #   DataTable turns it off and paints it as its own toolbar control.
        # @param preserved_params [Hash] Extra top-level params (e.g. an active
        #   `group_by`) rendered as hidden fields so the GET submit keeps them.
        #   Non-filter params already in the `url:` query string travel too
        #   (same semantics as Filters::Component); on a key collision the
        #   explicit hash wins.
        # rubocop:disable Metrics/ParameterLists
        def initialize(url:, filters: [], show_clear: false, search: nil, storage_id: nil,
                       persist_enabled: false, persistence_toggle: true, preserved_params: {})
          # rubocop:enable Metrics/ParameterLists
          @url = url
          @filters = filters
          @show_clear = show_clear
          @search = Bali::SearchConfig.wrap(search)
          @storage_id = storage_id
          @persist_enabled = persist_enabled
          @persistence_toggle = persistence_toggle
          @preserved_params = preserved_params || {}
        end

        def render?
          @filters.any? || search_enabled?
        end

        def show_clear?
          @show_clear
        end

        def search_enabled?
          @search.enabled?
        end

        # "q[name_or_email_cont]"
        def search_field_name
          @search.param_name
        end

        def search_value
          @search.value
        end

        def search_placeholder
          @search.placeholder
        end

        def search_icon
          @search.icon
        end

        def search_width
          @search.width.presence || "w-48 sm:w-96"
        end

        def filter_type(filter)
          filter[:type]&.to_sym
        end

        def toggle_group?(filter)
          filter_type(filter) == :toggle_group
        end

        def slim_select?(filter)
          filter_type(filter) == :slim_select
        end

        def date?(filter)
          filter_type(filter) == :date
        end

        def date_range?(filter)
          filter_type(filter) == :date_range
        end

        def date_filter?(filter)
          date?(filter) || date_range?(filter)
        end

        # A date range offered as named periods ("This month") with the picker behind a
        # "Custom…" option. Only `date_range` gets them: "this week" is not a value a
        # single date can hold.
        def presets?(filter)
          date_range?(filter) && filter[:presets].present?
        end

        def boolean?(filter)
          filter_type(filter) == :boolean
        end

        def radio_group?(filter)
          filter_type(filter) == :radio_group
        end

        def number_range?(filter)
          filter_type(filter) == :number_range
        end

        def select?(filter)
          filter_type(filter) == :select
        end

        def filter_field_name(filter)
          predicate = filter[:predicate] || (date_range?(filter) ? nil : :eq)
          name = predicate.present? ? "q[#{filter[:attribute]}_#{predicate}]" : "q[#{filter[:attribute]}]"
          toggle_group?(filter) ? "#{name}[]" : name
        end

        # The period select's options: "no filter", the declared presets, "Custom…".
        # The picker itself is a fourth state of the same control, not a fifth option.
        def preset_options(filter)
          [ [ preset_blank_label(filter), "" ] ] +
            Bali::DateRangePresets.options(filter[:presets]) +
            [ [ t("bali_view.simple_filters.presets.custom"), Bali::DateRangePresets::CUSTOM ] ]
        end

        # A date range filter has no blank option to name today, so `blank:` is free for it
        # and most call sites will not have bothered.
        def preset_blank_label(filter)
          filter[:blank].presence || t("bali_view.simple_filters.presets.any")
        end

        # Which option the request came back on. Anything that is not a token but is set is
        # a range the user typed or picked, so the select lands on "Custom…" and the picker
        # comes back holding it.
        def preset_select_value(filter)
          value = preset_current_value(filter)
          return "" if value.blank?

          Bali::DateRangePresets.token?(value) ? value : Bali::DateRangePresets::CUSTOM
        end

        def preset_custom_value(filter)
          value = preset_current_value(filter)
          Bali::DateRangePresets.token?(value) ? nil : value
        end

        # The one control that submits. Rendered with the value the request carried so the
        # form is correct before Stimulus connects — the controller rewrites it from
        # whichever control the user touches afterwards.
        def preset_current_value(filter)
          (filter[:value] || filter[:default]).presence&.to_s
        end

        def number_range_field_names(filter)
          {
            min: "q[#{filter[:attribute]}_gteq]",
            max: "q[#{filter[:attribute]}_lteq]"
          }
        end

        def number_range_values(filter)
          values = filter[:value] || filter[:default] || {}
          values = {} unless values.is_a?(Hash)
          values
        end

        # El caption visible sobre el control. `label: false` lo quita a propósito (#882),
        # y un hash de filtro escrito a mano puede no traer la clave: los dos casos son
        # "sin rótulo".
        #
        # Va aparte del nombre accesible porque las dos preguntas se contestan al revés: el
        # caption se IMPRIME cuando existe, el `aria-label` se emite cuando NO existe. Un
        # solo helper no puede servir a las dos — el toggle booleano pinta su rótulo al lado
        # del switch y a la vez necesita nombrarse cuando no lo tiene.
        def filter_caption(filter)
          filter[:label].presence
        end

        def captioned?(filter)
          filter_caption(filter).present?
        end

        # El nombre accesible del control, que no es el caption: sin rótulo el control tiene
        # que nombrarse igual o el lector anuncia un "cuadro combinado" pelado (#1155, WCAG
        # 4.1.2).
        #
        # `aria_label:` es el nombre explícito. A falta de él cae en el rótulo —que existe
        # aunque la rama no lo dibuje— y por último en el texto de la opción en blanco, que
        # es la promesa que `label: false` ya tenía escrita y nunca cumplió: "un control que
        # ya se nombra solo con su opción en blanco" ("Todos los años").
        #
        # El `blank:` sólo cuenta si es una cadena: `include_blank: true` es válido en Rails
        # y pinta una opción vacía, así que un `blank: true` nombraría el control "true" —
        # el mismo bug que la palabra "false" que este cambio quita de la rama booleana.
        def accessible_filter_name(filter)
          explicit = filter[:aria_label].presence || filter_caption(filter)
          return explicit if explicit.present?

          filter[:blank] if filter[:blank].is_a?(String) && filter[:blank].present?
        end

        # Un `aria-label` sobre un control al que YA apunta un `<label for>` visible sería un
        # segundo nombre diciendo lo mismo: se emite sólo donde el caption no llega. La
        # excepción es `slim_select`, que tiene su propio helper porque ahí el caption nunca
        # llega.
        def aria_label_for(filter)
          accessible_filter_name(filter) unless captioned?(filter)
        end

        # SlimSelect recorta el `<select>` real a 1x1 (`bali/slim_select.css`) y dibuja su
        # propio `div[role="combobox"]`, al que copia el `aria-label`/`aria-labelledby` del
        # select y nada más — el `<label for>` no viaja, su `setupLabelHandlers` sólo cablea
        # clicks. Medido en el árbol de accesibilidad: un slim_select CON caption se
        # anunciaba "Combobox", el default del widget. O sea que ésta es la única rama donde
        # el aria se emite también en el caso captionado, y la única que apunta al caption
        # con `aria-labelledby` en vez de repetir el texto.
        def slim_select_aria(filter)
          return { "aria-labelledby": filter_label_id(filter) } if captioned?(filter)

          name = accessible_filter_name(filter)
          name.present? ? { "aria-label": name } : {}
        end

        # El select de períodos siempre tiene de dónde caer: `blank:`, y si el filtro no lo
        # declara, la misma cadena que ya nombra su opción en blanco ("Cualquier fecha").
        def preset_accessible_name(filter)
          accessible_filter_name(filter).presence || preset_blank_label(filter)
        end

        # El caption sobre varios controles nombra al GRUPO, no a uno de ellos. Sin caption
        # el grupo se queda con el nombre accesible resuelto; sin ninguno de los dos no hay
        # nombre que poner y el `role` solo no agrega nada.
        def group_attributes(filter)
          return {} unless multi_control?(filter)
          return { role: "group", "aria-labelledby": filter_label_id(filter) } if captioned?(filter)

          name = accessible_filter_name(filter)
          name.present? ? { role: "group", "aria-label": name } : {}
        end

        # A filter whose caption cannot be a `<label for>` because it has no
        # single control to point at. Those get a `role="group"` named by the
        # caption instead, which is what a caption over several controls is.
        def multi_control?(filter)
          toggle_group?(filter) || radio_group?(filter) || number_range?(filter)
        end

        # Controls that filter on change instead of waiting for the Filter button:
        # the pills and the native select (#996), where a change event is a
        # completed choice. Restricted here as well as in the DSL, because the
        # instance-level `simple_filters:` hashes come in unvalidated.
        def auto_submit?(filter)
          return false unless filter[:auto_submit]

          toggle_group?(filter) || radio_group?(filter) || select?(filter)
        end

        def any_auto_submit?
          @filters.any? { |filter| auto_submit?(filter) }
        end

        # `submit-on-change` is only mounted when a filter asked for it, so a row
        # without pills keeps the exact markup it had.
        def form_data_attributes
          data = { turbo_frame: "_top" }
          data[:controller] = "submit-on-change" if any_auto_submit?
          data
        end

        # `#submit` and not `#debouncedSubmit`: a pill click or a select choice is a
        # finished choice, and the phantom submit that immediacy used to risk is what
        # the controller's own connect guard now absorbs.
        #
        # `change->` spelled out because Stimulus's default event for an `<input>` is
        # `input`, not `change`. Both fire on a checkbox or radio click, so the two
        # behave the same there — but the one that reads right is the one written,
        # and on a `<select>` it is also the one that fires once per selection.
        def auto_submit_attributes(filter)
          return {} unless auto_submit?(filter)

          { data: { action: "change->submit-on-change#submit" } }
        end

        # Derived from the Ransack param name, not from the attribute: the
        # predicate is what tells two filters over the same column apart, and it
        # is already assumed unique — two filters sharing a name would be
        # fighting over the same param anyway.
        def filter_control_id(filter)
          "simple-filter-#{filter_field_name(filter).gsub(/[^a-zA-Z0-9_-]+/, "-").squeeze("-").delete_suffix("-")}"
        end

        def filter_label_id(filter)
          "#{filter_control_id(filter)}-label"
        end

        def search_input_id
          "simple-filter-search-#{search_field_name.gsub(/[^a-zA-Z0-9_-]+/, "-").squeeze("-").delete_suffix("-")}"
        end

        # Documented since the component was written but never rendered, which
        # left the search box named by its placeholder alone.
        def search_label
          @search.label
        end

        def icon_addon(icon_name)
          return unless icon_name

          tag.div(class: "join-item btn btn-sm btn-disabled no-animation border-base-content/20 bg-base-200 text-base-content/60 px-2.5") do
            render Bali::Icon::Component.new(icon_name, class: "w-4 h-4")
          end
        end

        # Sin filtros declarados el botón no filtra nada: lo único que manda es el término
        # de búsqueda, y "Filtrar" nombra algo que en esa pantalla no existe. La cadena
        # para ese caso ya estaba en el paquete —`filters.submit_search`, hoy usada como
        # `aria-label` del buscador del panel completo— así que no suma traducciones.
        def apply_button_text
          return I18n.t("bali_view.filters.submit_search") if @filters.blank?

          I18n.t("bali_view.simple_filters.apply")
        end

        def clear_button_text
          I18n.t("bali_view.simple_filters.clear")
        end

        # Navegar a la URL pelada NO limpia: para el server es indistinguible de "no vino
        # ningún filtro", y con la persistencia encendida ese es justo el caso que RESTAURA
        # lo guardado — el usuario limpiaba y el listado le devolvía el filtro. `clear_filters`
        # es lo único que dispara el borrado de la caché (`FilterForm`: `Rails.cache.delete`).
        # Las otras dos rutas de limpieza ya lo mandaban (`AppliedTags#clear_all_url` y
        # `clearFiltersAndClose` del JS); ésta se había quedado afuera.
        #
        # Se AGREGA al query string en vez de reemplazarlo: la `url:` del listado puede traer
        # params propios del host (`request.fullpath`, un scope), y perderlos al limpiar
        # mandaría al usuario a otra vista.
        #
        # Y arrastra los MISMOS pares que el submit emite como hidden fields
        # (`preserved_query_params`): limpiar quita los filtros, no el estado de la vista.
        # Sin esto el link tiraba la agrupación, el modo de visualización y los
        # `preserved_params:` del host que el submit de al lado acababa de conservar —
        # el panel ya lo hacía así (`clearFiltersAndClose` re-lee los hidden fields).
        def clear_href
          preserved_query_params.reduce(add_query_param(@url, :clear_filters, true)) do |url, (name, value)|
            add_query_param(url, name, value)
          end
        end

        def before_render
          warn_unnamed_filters
        end

        private

        # Un filtro sin caption, sin `aria_label:` y sin `blank:` del que caer no tiene
        # nombre posible: `boolean`, `toggle_group`, `radio_group`, `number_range` y las dos
        # de fecha no tienen opción en blanco de dónde sacarlo.
        #
        # No revienta. El issue pedía un `ArgumentError`, y eso rompería en producción a un
        # anfitrión —y a la propia `UncaptionedSimpleFilterForm` del repo— por un defecto de
        # accesibilidad que no impide usar la pantalla. Avisa donde se puede arreglar y
        # sigue, como `AppLayout#check_sidebar_sync!`.
        #
        # Y a diferencia del aviso de persistencia (#1029, sólo development) éste también
        # suena en test: aquel describía una configuración que sólo está mal en el entorno
        # del anfitrión, éste describe markup que sale igual de mudo en los tres. Una vez por
        # control y por proceso, para no llenar la suite de un anfitrión con la misma línea.
        def warn_unnamed_filters
          return unless Rails.env.development? || Rails.env.test?

          @filters.each do |filter|
            next if filter_has_a_name?(filter)

            key = filter_control_id(filter)
            next if (self.class.unnamed_filter_warnings_issued ||= Set.new).include?(key)

            self.class.unnamed_filter_warnings_issued << key
            Rails.logger.warn(
              "[Bali] SimpleFilters \"#{filter[:attribute]}\": the control renders with no " \
              "accessible name — no caption, no `aria_label:`, and no `blank:` text to fall " \
              "back on — so a screen reader announces it unnamed (WCAG 4.1.2). Pass " \
              "`aria_label:` on the filter, or give it a caption."
            )
          end
        end

        # `presets` se nombra siempre: `preset_blank_label` cae en una cadena traducida.
        def filter_has_a_name?(filter)
          presets?(filter) || accessible_filter_name(filter).present?
        end

        class << self
          attr_accessor :unnamed_filter_warnings_issued
        end
      end
    end
  end
end
