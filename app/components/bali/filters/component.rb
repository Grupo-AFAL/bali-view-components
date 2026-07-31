# frozen_string_literal: true

module Bali
  module Filters
    class Component < ApplicationViewComponent
      # `saved_view` NO se preserva: re-enviarlo hace que el server re-aplique el payload de
      # la vista, pisando en silencio los filtros o la búsqueda que el usuario acaba de
      # escribir. (`page` sí viaja: preservarlo es comportamiento deliberado de Bali.)
      EXCLUDED_PARAMS = %w[q clear_filters clear_search saved_view].freeze

      attr_reader :url, :available_attributes, :apply_mode, :id, :popover, :combinator,
                  :filter_groups, :max_groups, :storage_id, :persist_enabled, :turbo_stream

      # Renders the applied filter pills above the filter builder
      renders_one :applied_tags, ->(**options) do
        AppliedTags::Component.new(
          filter_groups: @filter_groups,
          available_attributes: @available_attributes,
          url: @url,
          **options
        )
      end

      # @param url [String] The URL to submit filters to
      # @param available_attributes [Array<Hash>] Available filterable attributes
      #   Each hash should have: { key:, label:, type:, options: (for select) }
      #   Types: :text, :number, :date, :datetime, :select, :boolean
      # @param filter_groups [Array<Hash>] Initial filter state (from URL params)
      # @param apply_mode [Symbol] :batch (default) or :live
      # @param combinator [Symbol] :and (default) or :or - how groups are combined
      # @param max_groups [Integer] Maximum number of filter groups allowed
      # @param popover [Boolean] Whether to show filters in a popover (default: true)
      # @param button_text [String] Text for the popover trigger button
      # @param search [Hash] Quick search configuration
      #   - :fields [Array<Symbol>] Fields to search (e.g., [:name, :description])
      #   - :value [String] Current search value from URL params
      #   - :placeholder [String] Placeholder text for search input
      # @param storage_id [String] Optional storage ID indicating filters can be persisted
      # @param persist_enabled [Boolean] Whether user has opted into filter persistence
      # @param persistence_toggle [Boolean] Render the bookmark toggle inside this panel
      #   (default: true). DataTable turns it off and paints it as its own toolbar control.
      # @param turbo_stream [Boolean] Whether to accept Turbo Stream responses (default: false)
      #   When true, forms will include data-turbo-stream="true" to accept stream responses.
      #   The URL is still updated via JavaScript before form submission.
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        url:,
        available_attributes:,
        filter_groups: [],
        apply_mode: :batch,
        combinator: nil,
        max_groups: 10,
        popover: true,
        button_text: nil,
        search: {},
        storage_id: nil,
        persist_enabled: false,
        persistence_toggle: true,
        turbo_stream: false,
        preserved_params: {},
        **options
      )
        @url = url
        @preserved_params = preserved_params || {}
        @available_attributes = normalize_attributes(available_attributes)
        @filter_groups = filter_groups.presence || [ default_filter_group ]
        @apply_mode = apply_mode
        # `@applied_combinator` es nil cuando el estado NO traía `q[m]`; `@combinator` conserva
        # el default de render ("and"). Re-emitir el default como si fuera elección del usuario
        # volteaba a AND un OR aplicado en el siguiente round-trip.
        @applied_combinator = combinator.presence&.to_s
        @combinator = @applied_combinator || "and"
        @max_groups = max_groups
        @popover = popover
        @button_text = button_text
        @search = search || {}
        @storage_id = storage_id
        @persist_enabled = persist_enabled
        @persistence_toggle = persistence_toggle
        @turbo_stream = turbo_stream
        @id = options[:id] || "filters-#{SecureRandom.hex(4)}"
      end
      # rubocop:enable Metrics/ParameterLists

      # Returns true if persistence is available (storage_id is configured)
      def persistence_available?
        @storage_id.present?
      end

      # Returns true if user has enabled persistence
      def persist_enabled?
        @persist_enabled
      end

      # El DataTable pinta el marcador como control propio de la toolbar y apaga este: dos
      # controladores `filter-persistence` sobre el mismo storage_id se pisan el localStorage
      # y la cookie. Apaga SOLO el toggle — el panel sigue necesitando storage_id y
      # persist_enabled para su leyenda "Auto-guardado".
      def persistence_toggle?
        @persistence_toggle
      end

      def button_text
        @button_text || I18n.t("bali_view.filters.filters_button")
      end

      def search_enabled?
        @search[:fields].present?
      end

      def search_value
        @search[:value]
      end

      def search_placeholder
        @search[:placeholder] || I18n.t("bali_view.filters.search_placeholder")
      end

      # Build Ransack field name for multi-field search (e.g., "name_or_genre_cont")
      def search_field_name
        return nil unless search_enabled?

        fields = @search[:fields].map(&:to_s).join("_or_")
        "q[#{fields}_cont]"
      end

      def active_filter_count
        @filter_groups.sum do |group|
          group[:conditions]&.count { |c| c[:attribute].present? && c[:value].present? } || 0
        end
      end

      def active_filters?
        active_filter_count.positive?
      end

      # Serialize attributes for Stimulus controller
      def attributes_json
        @available_attributes.map do |attr|
          {
            key: attr[:key].to_s,
            label: attr[:label],
            type: attr[:type].to_s,
            options: attr[:options] || [],
            operators: operators_for_type(attr[:type])
          }
        end.to_json
      end

      # Build the default operators for each attribute type.
      # Delegates to Operators module for centralized definitions.
      def operators_for_type(type)
        Operators.for_type(type)
      end

      # Translations JSON for Stimulus controllers (combinators only for main controller)
      def translations_json
        {
          combinators: {
            and: I18n.t("bali_view.filters.combinators.and"),
            or: I18n.t("bali_view.filters.combinators.or")
          }
        }.to_json
      end

      # Extract non-filter query params to preserve them when submitting.
      # Combines params parsed from the URL with any explicitly-passed
      # `preserved_params` (e.g. an active `group_by`), which win on key
      # collisions. Returns an array of [name, value] pairs for hidden_field_tag.
      def preserved_query_params
        query_string = URI.parse(url).query
        from_url = if query_string.blank?
                     []
        else
                     params = Rack::Utils.parse_nested_query(query_string)
                     flatten_params(params.except(*EXCLUDED_PARAMS))
        end

        explicit = flatten_params(@preserved_params.stringify_keys).reject { |_, value| value.to_s.blank? }
        explicit_keys = explicit.map(&:first)
        from_url.reject { |name, _| explicit_keys.include?(name) } + explicit
      end

      # Render hidden fields for preserved params (call from template).
      # `id: nil` como en active_filter_hidden_fields: en modo popover estos campos se pintan
      # en los DOS forms (búsqueda rápida y panel), y con id derivado del name quedaban ids
      # duplicados en el documento.
      def preserved_params_hidden_fields
        safe_join(
          preserved_query_params.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) }
        )
      end

      # Hidden fields carrying the APPLIED filter state (q[g][...]/q[m]), so the quick-search
      # form preserves active filters instead of clearing them. Serializes `filter_groups`
      # back into the same Ransack param shape the filter form submits; the consolidated
      # `between` operator expands back to its gteq/lteq pair.
      def active_filter_hidden_fields
        safe_join(
          active_filter_params.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) }
        )
      end

      private

      # [name, value] pairs of the applied filter state. Only real conditions travel
      # (attribute + value present); empty builder rows stay out so the server keeps
      # treating "solo búsqueda, sin filtros" igual que hoy cuando no hay filtros activos.
      def active_filter_params
        pairs = []
        filter_groups.each_with_index do |group, index|
          # Se descartan las filas vacías del builder Y las que no producen ningún par real
          # (un `between` con ambos extremos en blanco pasa `present?` por ser un Hash, y
          # emitía un grupo fantasma: solo los `m`, sin una sola condición).
          conditions = (group[:conditions] || []).select do |condition|
            condition[:attribute].present? && condition[:value].present? &&
              condition_params(condition, 0).any?
          end
          next if conditions.empty?

          pairs << [ "q[g][#{index}][m]", group[:combinator] ] if group[:combinator].present?
          conditions.each { |condition| pairs.concat(condition_params(condition, index)) }
        end
        pairs << [ "q[m]", @applied_combinator ] if pairs.any? && @applied_combinator.present?
        pairs
      end

      def condition_params(condition, group_index)
        base = "q[g][#{group_index}][#{condition[:attribute]}"
        if condition[:operator] == "between"
          value = condition[:value] || {}
          [ [ "#{base}_gteq]", value[:start] || value["start"] ],
            [ "#{base}_lteq]", value[:end] || value["end"] ] ].reject { |_, v| v.blank? }
        elsif condition[:value].is_a?(Array)
          condition[:value].map { |v| [ "#{base}_#{condition[:operator]}][]", v ] }
        else
          [ [ "#{base}_#{condition[:operator]}]", condition[:value] ] ]
        end
      end

      # Recursively flatten nested params hash into [name, value] pairs.
      # e.g., {"sort" => {"column" => "name"}} becomes [["sort[column]", "name"]]
      def flatten_params(params, prefix = nil)
        params.flat_map do |key, value|
          field_name = prefix ? "#{prefix}[#{key}]" : key.to_s

          case value
          when Hash  then flatten_params(value, field_name)
          when Array then value.map { |v| [ "#{field_name}[]", v ] }
          else            [ [ field_name, value ] ]
          end
        end
      end

      def normalize_attributes(attributes)
        attributes.map do |attr|
          {
            key: attr[:key],
            label: attr[:label] || attr[:key].to_s.humanize,
            type: attr[:type] || :text,
            options: attr[:options] || []
          }
        end
      end

      def default_filter_group
        {
          combinator: "or",
          conditions: [ default_condition ]
        }
      end

      def default_condition
        {
          attribute: "",
          operator: "cont",
          value: ""
        }
      end
    end
  end
end
