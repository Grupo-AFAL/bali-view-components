# frozen_string_literal: true

module Bali
  module DataTable
    class Component < ApplicationViewComponent
      attr_reader :filters_class

      delegate :pagy_bulma_nav, to: :helpers

      renders_one :custom_pagy_nav
      renders_one :filters_panel, ->(text_field:, opened:, auto_submit_search_input: false) do
        Filters::Component.new(
          form: @filter_form,
          url: @url,
          text_field: text_field,
          opened: opened,
          auto_submit_search_input: auto_submit_search_input
        )
      end

      renders_one :summary
      renders_one :table

      def initialize(filter_form:, url:, pagy: nil, **options)
        @filter_form = filter_form
        @url = url
        @pagy = pagy
        @table_wrapper_class = options.delete(:table_class)
        @filters_class = options.delete(:filters_class)
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
