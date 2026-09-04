# frozen_string_literal: true

module Bali
  module Filters
    class Component < ApplicationViewComponent
      include Bali::Filters::PreservedParams
      include Bali::Filters::Persistable

      attr_reader :url, :available_attributes, :apply_mode, :id, :popover, :combinator,
                  :filter_groups, :max_groups, :turbo_stream

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
      # @param search [Hash] Quick search configuration (see Bali::SearchConfig)
      #   - :fields [Array<Symbol>] Fields to search (e.g., [:name, :description])
      #   - :value [String] Current search value from URL params
      #   - :placeholder [String] Placeholder text for search input
      #   - :label [String] Accessible name for the search input
      #   - :icon [String] Icon for the submit button (default: "search")
      #   - :width [String] Width classes for the search box
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
        @search = Bali::SearchConfig.wrap(search)
        @storage_id = storage_id
        @persist_enabled = persist_enabled
        @persistence_toggle = persistence_toggle
        @turbo_stream = turbo_stream
        @id = options[:id] || "filters-#{SecureRandom.hex(4)}"
      end
      # rubocop:enable Metrics/ParameterLists

      def button_text
        @button_text || I18n.t("bali_view.filters.filters_button")
      end

      def search_enabled?
        @search.enabled?
      end

      def search_value
        @search.value
      end

      def search_placeholder
        @search.placeholder || I18n.t("bali_view.filters.search_placeholder")
      end

      # An accessible name for the box, when the caller has one better than the
      # placeholder. Nil drops the attribute rather than emitting an empty one.
      def search_label
        @search.label.presence
      end

      def search_icon
        @search.icon.presence || "search"
      end

      # The width the box WANTS, not a floor: `min-w-0` stays outside it so a
      # cramped toolbar can still shrink the field instead of overflowing.
      def search_width
        @search.width.presence || "w-full sm:w-64"
      end

      # "q[name_or_genre_cont]"
      def search_field_name
        @search.param_name
      end

      # Misma regla que decide qué viaja y que la que cuenta `FilterForm#active_filters_count`
      # (#1085): un `between` con los dos extremos en blanco pasa `present?` por ser un Hash,
      # así que el badge decía "1 filtro" sobre una fila que no aportaba un solo par.
      def active_filter_count
        @filter_groups.sum do |group|
          Array(group[:conditions]).count { |c| ActiveFilterParams.applied?(c) }
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
          },
          combinator_toggle: I18n.t("bali_view.filters.combinator_toggle")
        }.to_json
      end

      # Hidden fields carrying the APPLIED filter state (q[g][...]/q[m]), so the quick-search
      # form preserves active filters instead of clearing them. The serialization lives in
      # `Bali::Filters::ActiveFilterParams` because a bulk action posting "act on the whole
      # filtered result" has to say WHICH result with the very same pairs.
      def active_filter_hidden_fields
        safe_join(
          active_filter_params.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) }
        )
      end

      private

      def active_filter_params
        ActiveFilterParams.group_pairs(filter_groups, combinator: @applied_combinator)
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
          combinator: FilterGroup::Component::DEFAULT_COMBINATOR,
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
