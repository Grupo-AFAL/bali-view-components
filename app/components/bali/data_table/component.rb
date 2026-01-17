# frozen_string_literal: true

module Bali
  module DataTable
    class Component < ApplicationViewComponent
      attr_reader :pagy

      renders_one :custom_pagy_nav
      renders_one :actions_panel, ->(
        export_formats: [], display_mode_param_name: :data_display_mode,
        grid_display_mode_enabled: false
      ) do
        ActionsPanel::Component.new(
          filter_form: @filter_form, url: @url, display_mode: @display_mode,
          grid_display_mode_enabled: grid_display_mode_enabled,
          export_formats: export_formats,
          display_mode_param_name: display_mode_param_name
        )
      end

      # Filters panel using AdvancedFilters component
      # @param available_attributes [Array<Hash>] Filterable attributes
      #   Each hash: { key:, label:, type: :text/:number/:date/:select/:boolean, options: }
      # @param filter_groups [Array<Hash>] Initial filter state from params (optional)
      # @param search_fields [Array<Symbol>] Fields for quick search (e.g., [:name, :description])
      # @param search_value [String] Current search value from URL params
      # @param apply_mode [Symbol] :batch (default) or :live
      # @param popover [Boolean] Show filters in popover (default: true)
      renders_one :filters_panel, ->(
        available_attributes:,
        filter_groups: [],
        search_fields: [],
        search_value: nil,
        apply_mode: :batch,
        popover: true,
        **options
      ) do
        AdvancedFilters::Component.new(
          url: @url,
          available_attributes: available_attributes,
          filter_groups: filter_groups,
          search_fields: search_fields,
          search_value: search_value,
          apply_mode: apply_mode,
          popover: popover,
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
      # @param button_label [String] Label for the dropdown button
      # @param button_icon [String] Icon name
      # @yield [column_selector] Block to define columns
      # @yieldparam column_selector [ColumnSelector::Component] The component
      renders_one :column_selector, ->(
        table_id:,
        button_label: 'Columns',
        button_icon: 'table',
        &block
      ) do
        component = ColumnSelector::Component.new(
          table_id: table_id,
          button_label: button_label,
          button_icon: button_icon
        )
        # Yield to allow column definitions via with_column
        block&.call(component)
        component
      end

      # Built-in export dropdown with format options
      # @param formats [Array<Symbol>] Export formats (e.g., [:csv, :excel, :pdf])
      # @param url [String] Base URL for export (optional, defaults to current URL)
      # @param button_label [String] Label for the dropdown button
      # @param button_icon [String] Icon name
      renders_one :export, ->(
        formats: %i[csv excel pdf],
        url: nil,
        button_label: 'Export',
        button_icon: 'download'
      ) do
        Export::Component.new(
          formats: formats,
          url: url,
          button_label: button_label,
          button_icon: button_icon
        )
      end

      # @param url [String] Base URL for filtering/sorting links
      # @param filter_form [Bali::FilterForm] Optional filter form for Ransack integration
      # @param pagy [Pagy] Optional Pagy object for pagination
      # @param show_summary [Boolean] Show "Showing X-Y of Z" summary (default: true when pagy present)
      # @param summary_position [Symbol] :bottom (default) or :top
      # @param item_name [String] Name for items in summary (default: "items", e.g., "movies", "users")
      def initialize(url:, filter_form: nil, pagy: nil, show_summary: nil, summary_position: :bottom,
                     item_name: 'items', **options)
        @filter_form = filter_form
        @url = url
        @pagy = pagy
        @show_summary = show_summary.nil? ? pagy.present? : show_summary
        @summary_position = summary_position
        @item_name = item_name
        @table_wrapper_class = options.delete(:table_class)

        @display_mode = options.delete(:display_mode) || :table
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
          item_name: @item_name
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
    end
  end
end
