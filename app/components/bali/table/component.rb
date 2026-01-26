# frozen_string_literal: true

module Bali
  module Table
    class Component < ApplicationViewComponent
      TABLE_CLASSES = 'table table-zebra w-full'
      CONTAINER_CLASSES = 'overflow-x-auto table-component'
      STICKY_CLASSES = 'overflow-visible [&_table]:overflow-x-auto ' \
                       '[&_thead_tr]:sticky [&_thead_tr]:bg-base-100 [&_thead_tr]:top-[3.75rem]'

      class MissingFilterForm < StandardError; end

      renders_many :headers, ->(name: nil, sort: nil, **options) do
        Header::Component.new(form: @form, name: name, sort: sort, **options)
      end

      renders_many :rows, ->(skip_tr: false, **options) do
        Row::Component.new(skip_tr: skip_tr, bulk_actions: bulk_actions?, **options)
      end

      renders_many :footers, Footer::Component

      renders_one :new_record_link, ->(name:, href:, modal: true, **options) do
        Bali::Link::Component.new(name: name, href: href, type: :success, modal: modal, **options)
      end

      renders_one :no_records_notification
      renders_one :no_results_notification

      attr_reader :options, :tbody_options, :table_container_options

      def initialize(form: nil, bulk_actions: [], sticky_headers: false, **options)
        @form = form
        @bulk_actions = bulk_actions
        @sticky_headers = sticky_headers
        @tbody_options = hyphenize_keys(options.delete(:tbody) || {})
        @table_container_options = build_container_options(options.delete(:table_container) || {})
        @options = prepend_class_name(hyphenize_keys(options), TABLE_CLASSES)
      end

      def container_id
        @options[:id] || @form&.id
      end

      def bulk_actions?
        @bulk_actions.any?
      end

      def visible_headers
        headers.reject(&:hidden)
      end

      def empty_state_content
        if @form&.active_filters?
          no_results_notification || tag.p(t('.no_results'), class: 'text-base-content/60')
        elsif no_records_notification.present?
          no_records_notification
        else
          safe_join([
            tag.p(t('.no_records'), class: 'text-base-content/60'),
            new_record_link
          ].compact)
        end
      end

      private

      def build_container_options(options)
        opts = prepend_class_name(options, container_classes)
        prepend_controller(opts, 'table')
      end

      def container_classes
        class_names(CONTAINER_CLASSES, @sticky_headers && STICKY_CLASSES)
      end

      def empty_table_row_id
        [container_id, 'empty-table-row'].compact.join('-')
      end
    end
  end
end
