# frozen_string_literal: true

module Bali
  module Widget
    # A COLLECTION: how many, and a preview of which.
    #
    #   class LowStockItems < Bali::Widget::ListBase
    #     default_size :medium
    #
    #     order_by :name
    #     row_title :name
    #     row_subtitle :outlet_name
    #     row_href { |item| item_path(item) }
    #
    #     def scope = Item.low_stock
    #   end
    #
    # The declarations are SYMBOLS SENT TO THE RECORD, which is the whole
    # ergonomic win over a block per field — `row_title :name` says everything a
    # `->(r) { r.name }` would. `row_href` takes a block because a path is built
    # from a helper rather than read off the record, and `row_subtitle` accepts
    # either: a symbol for one attribute, a block when it composes two.
    class ListBase < Base
      Row = Data.define(:title, :subtitle, :href) do
        def initialize(title:, subtitle: nil, href: nil) = super
      end

      class_attribute :_order_by
      class_attribute :_row_title
      class_attribute :_row_subtitle
      class_attribute :_row_href

      class << self
        # Applied to the scope before the preview is taken, never after: ordering
        # a limited relation orders the eight rows you already picked, which is
        # not the same query and usually not the one you meant.
        def order_by(value) = self._order_by = value

        def row_title(value = nil, &block) = self._row_title = value || block

        def row_subtitle(value = nil, &block) = self._row_subtitle = value || block

        def row_href(&block) = self._row_href = block
      end

      def count = safely(0) { scope.count.to_i }

      def items
        safely([]) do
          previewable.map { |record| Row.new(**row_for(record)) }
        end
      end

      private

      # ORDER THEN LIMIT. The reverse reads the first eight rows the database
      # happens to return and sorts those.
      def previewable
        ordered = _order_by.present? ? scope.order(_order_by) : scope

        ordered.limit(PREVIEW_ROWS)
      end

      def row_for(record)
        {
          title: resolve(_row_title, record),
          subtitle: resolve(_row_subtitle, record),
          href: _row_href && instance_exec(record, &_row_href)
        }
      end

      # A Symbol is sent to the record; a block runs against the WIDGET with the
      # record yielded, so it can reach route helpers and private methods.
      def resolve(field, record)
        case field
        when nil then nil
        when Symbol, String then record.public_send(field)
        else instance_exec(record, &field)
        end
      end
    end
  end
end
