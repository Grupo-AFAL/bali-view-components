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
        def clear_href
          add_query_param(@url, :clear_filters, true)
        end
      end
    end
  end
end
