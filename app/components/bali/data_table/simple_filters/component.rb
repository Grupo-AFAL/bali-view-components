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
        #   `group_by`) rendered as hidden fields so the GET submit keeps them
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

        attr_reader :storage_id

        # Top-level params to carry through the GET submit as hidden fields.
        # Blank values are dropped so no empty inputs are emitted.
        def preserved_params
          @preserved_params.reject { |_, value| value.to_s.blank? }
        end

        def render?
          @filters.any? || search_enabled?
        end

        def show_clear?
          @show_clear
        end

        # Returns true if user has enabled persistence
        def persist_enabled?
          @persist_enabled
        end

        # El DataTable pinta el marcador como control propio de la toolbar y apaga este: dos
        # controladores `filter-persistence` sobre el mismo storage_id se pisan el
        # localStorage y la cookie.
        def persistence_toggle?
          @persistence_toggle
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

        def boolean?(filter)
          filter_type(filter) == :boolean
        end

        def radio_group?(filter)
          filter_type(filter) == :radio_group
        end

        def number_range?(filter)
          filter_type(filter) == :number_range
        end

        def filter_field_name(filter)
          predicate = filter[:predicate] || (date_range?(filter) ? nil : :eq)
          name = predicate.present? ? "q[#{filter[:attribute]}_#{predicate}]" : "q[#{filter[:attribute]}]"
          toggle_group?(filter) ? "#{name}[]" : name
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
      end
    end
  end
end
