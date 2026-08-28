# frozen_string_literal: true

module Bali
  module Widget
    # A COLLECTION: how many, and a preview of which.
    #
    #   class LowStockItems < Bali::Widget::ListBase
    #     default_size :medium
    #
    #     list(order_by: :name) { Item.low_stock }
    #     row_title :name
    #     row_subtitle :outlet_name
    #     row_href { |item| item_path(item) }
    #   end
    #
    # The declarations are SYMBOLS SENT TO THE RECORD, which is the whole
    # ergonomic win over a block per field — `row_title :name` says everything a
    # `->(r) { r.name }` would. `row_href` takes a block because a path is built
    # from a helper rather than read off the record, and `row_subtitle` accepts
    # either: a symbol for one attribute, a block when it composes two.
    class ListBase < Base
      List = Data.define(:scope, :limit, :order_by) do
        def initialize(scope:, limit: PREVIEW_ROWS, order_by: nil) = super
      end

      Row = Data.define(:title, :subtitle, :href) do
        def initialize(title:, subtitle: nil, href: nil) = super
      end

      # No default: a `List` needs a scope, and there is no sensible empty one.
      # A widget that never declares `list` fails the way one that never defined
      # `#scope` used to — loudly, naming the macro.
      class_attribute :_list, **Base::ATTRIBUTE_OPTIONS
      class_attribute :_row_title, **Base::ATTRIBUTE_OPTIONS
      class_attribute :_row_subtitle, **Base::ATTRIBUTE_OPTIONS
      class_attribute :_row_href, **Base::ATTRIBUTE_OPTIONS

      class << self
        # The whole collection in one declaration: what to read, how to sort it,
        # how many to preview.
        #
        # `order_by` is applied to the scope BEFORE the preview is taken, never
        # after — ordering a limited relation sorts the eight rows you already
        # picked, which is not the same query and usually not the one you meant.
        #
        # PREFER THE BLOCK FORM. A class body is evaluated once at boot, so a
        # relation passed by value freezes whatever it closed over then:
        # `where(due_date: Date.current..)` is the day the process started, not
        # today, and the widget quietly shows the wrong week until a redeploy.
        # The block is re-evaluated per render and runs against the widget, so it
        # can also reach `context` and private helpers:
        #
        #   list(order_by: :due_date) { Task.due_after(Date.current) }
        #
        # A bare relation still works for a genuinely static scope.
        def list(scope: nil, limit: Base::PREVIEW_ROWS, order_by: nil, &block)
          unless scope || block
            raise ArgumentError, "`list` needs a scope: either `list(scope: …)` or `list { … }`."
          end

          self._list = List.new(scope: block || scope, limit: limit, order_by: order_by)
        end

        def row_title(value = nil, &block) = self._row_title = value || block

        def row_subtitle(value = nil, &block) = self._row_subtitle = value || block

        def row_href(&block) = self._row_href = block
      end

      def count = @count ||= safely(0) { scope.count.to_i }

      def items
        @items ||= safely([]) do
          previewable.map { |record| Row.new(**row_for(record)) }
        end
      end

      private

      # ORDER THEN LIMIT. The reverse reads the first eight rows the database
      # happens to return and sorts those.
      def previewable
        ordered = list.order_by.present? ? scope.order(list.order_by) : scope

        ordered.limit(list.limit)
      end

      def list
        _list || raise(NotImplementedError,
                       "#{self.class.name || 'This widget'} must declare `list`.")
      end

      # Resolved per render, which is the point of the block form.
      def scope
        declared = list.scope

        declared.is_a?(Proc) ? instance_exec(&declared) : declared
      end

      def row_for(record)
        # A list widget owes a title the way it owes a scope. Left to default to
        # nil, a widget with no `row_title` renders a column of blank rows and
        # looks like a data problem — so this fails the same loud way a missing
        # `list` does, naming the macro that fixes it.
        unless _row_title
          raise NotImplementedError,
                "#{self.class.name || 'This widget'} must declare `row_title`."
        end

        {
          title: resolve(_row_title, record),
          subtitle: resolve(_row_subtitle, record),
          href: _row_href && instance_exec(record, &_row_href)
        }
      end

      # A SYMBOL is sent to the record; a BLOCK runs against the WIDGET with the
      # record yielded, so it can reach route helpers and private methods.
      #
      # A STRING is the value itself, and used to be a third spelling of "send
      # this to the record" — which made `row_subtitle "In stock"` a confusing
      # `NoMethodError` at render time. It reads exactly like `title "Low stock
      # items"` three lines above it in the same class body, and `goal_label`
      # over in `ProgressBase` already treats a non-Proc as a literal. One
      # feature cannot have two answers to what a string means.
      def resolve(field, record)
        case field
        when nil, String then field
        when Symbol then record.public_send(field)
        else instance_exec(record, &field)
        end
      end
    end
  end
end
