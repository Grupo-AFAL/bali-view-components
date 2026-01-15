# frozen_string_literal: true

module Bali
  module DataTable
    class Component < ApplicationViewComponent
      attr_reader :filters_class

      delegate :pagy_nav, to: :helpers

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
      renders_one :filters_panel, ->(
        text_field:, opened:, auto_submit_search_input: false, **options
      ) do
        Filters::Component.new(
          form: @filter_form,
          url: @url,
          text_field: text_field,
          opened: opened,
          auto_submit_search_input: auto_submit_search_input,
          **options
        )
      end

      # Advanced filters panel for complex query building
      # @param available_attributes [Array<Hash>] Filterable attributes
      #   with :key, :label, :type, :options
      # @param filter_groups [Array<Hash>] Initial filter state from params
      # @param apply_mode [Symbol] :batch (default) or :live
      renders_one :advanced_filters_panel, ->(
        available_attributes:,
        filter_groups: [],
        apply_mode: :batch,
        **options
      ) do
        AdvancedFilters::Component.new(
          url: @url,
          available_attributes: available_attributes,
          filter_groups: filter_groups,
          apply_mode: apply_mode,
          **options
        )
      end

      renders_one :summary
      renders_one :table
      renders_one :grid

      def initialize(filter_form:, url:, pagy: nil, **options)
        @filter_form = filter_form
        @url = url
        @pagy = pagy
        @table_wrapper_class = options.delete(:table_class)
        @filters_class = options.delete(:filters_class)

        @display_mode = options.delete(:display_mode) || :table
      end

      def table_wrapper_classes
        @table_wrapper_class || 'box'
      end

      def id
        "data-table-#{@filter_form.id}"
      end
    end
  end
end
