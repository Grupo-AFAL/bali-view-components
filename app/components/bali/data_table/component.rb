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

      # Filters panel using AdvancedFilters component
      # @param available_attributes [Array<Hash>] Filterable attributes
      # @param filter_groups [Array<Hash>] Initial filter state from params (optional)
      # @param search_fields [Array<Symbol>] Fields for quick search
      # @param search_value [String] Current search value from URL params
      # @param apply_mode [Symbol] :batch (default) or :live
      # @param popover [Boolean] Show filters in popover (default: true)
      renders_one :filters_panel, ->(available_attributes:, **options) do
        AdvancedFilters::Component.new(
          url: @url,
          available_attributes: available_attributes,
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
