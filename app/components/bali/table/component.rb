# frozen_string_literal: true

module Bali
  module Table
    class Component < ApplicationViewComponent
      renders_many :headers, ->(name: nil, sort: nil, **options) do
        Header::Component.new(form: @form, name: name, sort: sort, **options)
      end

      renders_many :rows, ->(skip_tr: false, **options) do
        Row::Component.new(skip_tr: skip_tr, bulk_actions: @bulk_actions.any?, **options)
      end
      renders_many :footers, Footer::Component

      renders_one :new_record_link, ->(name:, href:, modal: true, **options) do
        Bali::Link::Component.new(name: name, href: href, type: :success, modal: modal, **options)
      end

      renders_one :no_records_notification
      renders_one :no_results_notification

      attr_reader :form, :options, :tbody_options, :table_container_options

      def initialize(form: nil, bulk_actions: [], **options)
        @form = form
        @bulk_actions = bulk_actions
        @tbody_options = hyphenize_keys(options.delete(:tbody) || {})
        @table_container_options = prepend_class_name(
          options.delete(:table_container) || {}, 'table-container table-component'
        )
        @table_container_options = prepend_controller(@table_container_options, 'table')

        @options = prepend_class_name(hyphenize_keys(options), 'table is-fullwidth')
      end

      def id
        @options[:id] || form&.id
      end

      class MissingFilterForm < StandardError; end

      private

      def empty_table_row_id
        [id, 'empty-table-row'].compact.join('-')
      end
    end
  end
end
