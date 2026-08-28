# frozen_string_literal: true

module Bali
  module Widget
    # A COLLECTION: how many, and a preview of which.
    #
    #   class LowStockItems < Bali::Widget::ListBase
    #     default_size :medium
    #
    #     list { Item.low_stock.order(:name) }
    #
    #     row_title :name
    #     row_subtitle :outlet_name
    #     row_href { |item| item_path(item) }
    #   end
    #
    # `list` is the primitive: `count` is the whole of it and the preview rows
    # are the first `limit` of it, so the collection is stated once. It carries
    # its own ordering, and Bali applies the limit afterwards.
    #
    # The ROW declarations are symbols sent to the RECORD, which is the whole
    # ergonomic win over a block per field — `row_title :name` says everything a
    # `->(r) { r.name }` would. `row_href` takes a block because a path is built
    # from a helper rather than read off the record, and `row_subtitle` accepts
    # any of three: a symbol for one attribute, a block when it composes two, a
    # string for a fixed label.
    class ListBase < Base
      # `limit` is always passed by the macro below, which is the one place a
      # `List` is built — so this carries no defaults of its own to fall out of
      # step with that signature.
      List = Data.define(:scope, :limit)

      Row = Data.define(:title, :subtitle, :href) do
        def initialize(title:, subtitle: nil, href: nil) = super
      end

      # `Row` is public — the card reads `row.title` and a host can name one.
      # A `List` is built in exactly one place and read only in here.
      private_constant :List

      # No default: a `List` needs a scope, and there is no sensible empty one.
      # A widget that never declares `list` fails the way one that never defined
      # `#scope` used to — loudly, naming the macro.
      class_attribute :_list, **ATTRIBUTE_OPTIONS
      class_attribute :_row_title, **ATTRIBUTE_OPTIONS
      class_attribute :_row_subtitle, **ATTRIBUTE_OPTIONS
      class_attribute :_row_href, **ATTRIBUTE_OPTIONS

      class << self
        # THE COLLECTION: what to read, and how many to preview.
        #
        # Ordering goes INSIDE the scope — `list { Movie.order(created_at: :desc) }`
        # — rather than in a keyword of its own. There is one obvious place to
        # write it, it is the place a Rails developer would write it anyway, and
        # `limit` is applied after the block returns, so a scope that orders
        # itself is always ordered before it is paged.
        #
        # A BLOCK, always — there is no way to pass a relation by value, and that
        # is the point. A class body is evaluated once at boot, so a relation
        # given there freezes whatever it closed over: `where(due_date:
        # Date.current..)` becomes the day the process started, and the tile shows
        # the wrong week until a redeploy. The reloader re-runs the class body on
        # every request, so that bug cannot reproduce in development and is silent
        # in production — the worst shape an API hazard can have. It is not a
        # hypothetical: this widget set shipped it twice.
        #
        # The block is also the only form that WORKS. It runs against the widget,
        # so it reaches `context` — a scope frozen into the class body can never
        # be tenant- or user-scoped, which is most widgets in a real host. And it
        # is shorter to write than the keyword it replaces.
        def list(limit: Base::PREVIEW_ROWS, &block)
          raise ArgumentError, "`list` needs a block: `list { Item.low_stock }`." unless block

          self._list = List.new(scope: block, limit: limit)
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

      # ORDER THEN LIMIT, still guaranteed — by construction now rather than by a
      # keyword. The scope carries its own `order`, and Bali applies `limit`
      # AFTER the block returns, so ordering written inside the scope is always
      # applied first. An unordered scope pages a preview off whatever the
      # database happened to return, which is a different bug in every database.
      #
      # `scope`, not `list.scope`: the declaration is a Proc in the block form,
      # and a Proc has no `limit`.
      def previewable = scope.limit(list.limit)

      def list
        _list || raise(NotImplementedError,
                       "#{self.class.name || 'This widget'} must declare `list`.")
      end

      # Re-read per render, which is the whole point of the block.
      def scope = instance_exec(&list.scope)

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
