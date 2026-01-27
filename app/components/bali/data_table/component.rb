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

      renders_one :summary
      renders_one :table
      renders_one :grid

      # Slot for right-aligned toolbar buttons (column selector, export, etc.)
      renders_many :toolbar_buttons

      # Built-in column selector with declarative API
      # @param table_id [String] CSS selector for the target table
      # @param button_label [String] Label for the dropdown button (i18n default)
      # @param button_icon [String] Icon name
      # @yield [column_selector] Block to define columns
      renders_one :column_selector, ->(table_id:, **opts, &block) do
        component = ColumnSelector::Component.new(table_id: table_id, **opts)
        block&.call(component)
        component
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
      # @param table_class [String] CSS class for table wrapper
      # @param display_mode [Symbol] :table (default) or :grid
      def initialize(url:, filter_form: nil, pagy: nil, **options)
        @filter_form = filter_form
        @url = url
        @pagy = pagy
        @show_summary = options.fetch(:show_summary) { pagy.present? }
        @summary_position = validate_summary_position(options[:summary_position])
        @item_name = options[:item_name]
        @table_wrapper_class = options[:table_class]
        @display_mode = (options[:display_mode] || :table).to_sym
      end

      def table_wrapper_classes
        @table_wrapper_class || 'overflow-x-auto'
      end

      def id
        @filter_form ? "data-table-#{@filter_form.id}" : "data-table-#{SecureRandom.hex(4)}"
      end

      # Auto-generated summary text from Pagy using I18n
      def default_summary_text
        return '' unless @pagy

        I18n.t(
          'view_components.bali.data_table.summary',
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

      def grid_mode?
        @display_mode == :grid
      end

      def show_toolbar?
        filters_panel? || toolbar_buttons? || column_selector? || export? || actions_panel?
      end

      def show_toolbar_right?
        toolbar_buttons? || column_selector? || export? || actions_panel?
      end

      private

      def item_name
        @item_name || I18n.t('view_components.bali.data_table.default_item_name')
      end

      def validate_summary_position(position)
        SUMMARY_POSITIONS.include?(position) ? position : :bottom
      end
    end
  end
end
