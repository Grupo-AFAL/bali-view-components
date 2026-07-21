# frozen_string_literal: true

module Bali
  module Table
    class Component < ApplicationViewComponent
      TABLE_CLASSES = "table table-zebra min-w-full"
      CONTAINER_CLASSES = "overflow-x-auto table-component"
      STICKY_CLASSES = "overflow-visible [&_table]:overflow-x-auto " \
                       "[&_thead_tr]:sticky [&_thead_tr]:bg-base-100 [&_thead_tr]:top-[3.75rem]"

      class MissingFilterForm < StandardError; end

      RowGroup = Struct.new(:value, :rows)

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

      def initialize(form: nil, bulk_actions: [], sticky_headers: false, group_counts: {}, **options)
        @form = form
        @bulk_actions = bulk_actions
        @sticky_headers = sticky_headers
        @group_counts = group_counts || {}
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

      def grouped?
        rows.any? { |row| !row.group.nil? }
      end

      # Consecutive rows sharing the same `group:` value collapse into one
      # RowGroup. The same value reappearing later starts a fresh group — the
      # caller owns the ordering (see docs), the component never re-sorts.
      def row_groups
        rows
          .chunk_while { |previous, current| previous.group == current.group }
          .map { |run| RowGroup.new(run.first.group, run) }
      end

      def group_colspan
        visible_headers.count + (bulk_actions? ? 1 : 0)
      end

      def group_label(value)
        value.nil? ? t(".ungrouped") : value.to_s
      end

      # Group-header text. When a global count exists for the group value (from
      # `group_counts:`, typically FilterForm#group_counts), it shows the global
      # total — "Norte (30)" — and appends a partial hint when the visible run is
      # smaller than that total because pagination split the group:
      # "Norte (30) — mostrando 25". Without a global count it falls back to the
      # page-local run size (v1 behavior).
      def group_header_text(group)
        label = group_label(group.value)
        total = global_group_count(group.value)

        return t(".group_count", group: label, count: group.rows.size) if total.nil?

        text = t(".group_count", group: label, count: total)
        text += " — #{t('.group_partial', shown: group.rows.size)}" if group.rows.size < total
        text
      end

      def empty_state_content
        if @form&.active_filters?
          no_results_notification || tag.p(t(".no_results"), class: "text-base-content/60")
        elsif no_records_notification.present?
          no_records_notification
        else
          safe_join([
            tag.p(t(".no_records"), class: "text-base-content/60"),
            new_record_link
          ].compact)
        end
      end

      private

      # Tolerant lookup of the global total for a group value. SQL group keys are
      # often strings while record attributes may be symbols/enums, so we try the
      # raw value then its string form. nil (SQL NULL group) is looked up as-is.
      # Returns nil on a miss so the header falls back to the page-local count.
      def global_group_count(value)
        return nil if @group_counts.blank?

        if @group_counts.key?(value)
          @group_counts[value]
        elsif !value.nil? && @group_counts.key?(value.to_s)
          @group_counts[value.to_s]
        end
      end

      def build_container_options(options)
        opts = prepend_class_name(options, container_classes)
        prepend_controller(opts, "table")
      end

      def container_classes
        class_names(CONTAINER_CLASSES, @sticky_headers && STICKY_CLASSES)
      end

      def empty_table_row_id
        [ container_id, "empty-table-row" ].compact.join("-")
      end
    end
  end
end
