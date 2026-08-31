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
    #     row do |r|
    #       r.title :name
    #       r.subtitle :outlet_name
    #       r.href { |item| item_path(item) }
    #     end
    #   end
    #
    # `list` is the primitive: `count` is the whole of it and the preview rows
    # are the first `limit` of it, so the collection is stated once. It carries
    # its own ordering, and Bali applies the limit afterwards.
    #
    # EVERY ROW FIELD TAKES THE SAME THREE FORMS:
    #
    #   a Symbol  is sent to the RECORD      r.title :name
    #   a block   runs on the WIDGET         r.href { |m| movie_path(m) }
    #   a String  is the value itself        r.subtitle "In stock"
    #
    # The block runs against the widget so it reaches route helpers, `context`,
    # private methods and `join` — which is why it takes the record as an
    # ARGUMENT rather than reading it off `self`.
    #
    # `r.title` is required. The other two default to nil.
    class ListBase < Base
      # How many preview rows a list widget loads, regardless of the size it is
      # rendered at — which is what keeps a widget from needing to know its size.
      # `count` still comes from the whole scope. A host raising
      # `Card::Component.rows_budget` past this raises `limit:` to match.
      PREVIEW_ROWS = 8

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

      # What `row` yields, and what turns a record into a `Row`. The three fields
      # live here rather than in three class attributes because a row is one
      # thing: it is built in one place and read in one place.
      #
      # Each setter writes its OWN ivar, so two `row` blocks MERGE per field
      # rather than the second replacing the first — which lets a shared module
      # declare a title and an href while a widget declares only its subtitle.
      class RowBuilder < Builder
        requires "r.title", block: "row"

        def title(value = nil, &block) = @title = block || value

        def subtitle(value = nil, &block) = @subtitle = block || value

        def href(value = nil, &block) = @href = block || value

        # `widget`, not just the record: a block form runs against the WIDGET, so
        # the builder has to borrow it. Passed per call rather than held, because
        # one builder belongs to the class and serves every instance of it.
        def to_row(widget, record)
          Row.new(
            title: resolve_field(widget, @title, record),
            subtitle: resolve_field(widget, @subtitle, record),
            href: resolve_field(widget, @href, record)
          )
        end

        private

        # NOT an override of `Builder#resolve` — a row resolves against a RECORD
        # as well as the widget, so it takes a third argument and needs its own
        # name rather than silently shadowing the shared one.
        #
        # A SYMBOL is sent to the record; a BLOCK runs against the WIDGET with the
        # record yielded, so it can reach route helpers and private methods.
        #
        # A STRING is the value itself, matching every other builder — `r.subtitle
        # "In stock"` reads like the `title "Low stock items"` above it.
        def resolve_field(widget, field, record)
          case field
          when nil, String then field
          when Symbol then record.public_send(field)
          else widget.instance_exec(record, &field)
          end
        end
      end
      private_constant :RowBuilder

      # No default: a `List` needs a scope, and a widget that never declares
      # `list` should fail loudly, naming the macro.
      class_attribute :_list, **ATTRIBUTE_OPTIONS

      # WHAT ONE ROW SAYS. Each field takes the same three forms, and each writes
      # its own ivar — so two `row` blocks merge field by field rather than the
      # second replacing the first, which lets a shared module declare what two
      # widgets have in common.
      declares :row, hint: "row { |r| r.title :name }" do
        RowBuilder.new
      end

      class << self
        # THE COLLECTION: what to read, and how many to preview.
        #
        # Ordering goes INSIDE the scope — `list { Movie.order(created_at: :desc) }`
        # — rather than in a keyword of its own. There is one obvious place to
        # write it, it is the place a Rails developer would write it anyway, and
        # `limit` is applied after the block returns, so a scope that orders
        # itself is always ordered before it is paged.
        #
        # A BLOCK, always. A class body is evaluated once at boot, so a relation
        # given by value freezes whatever it closed over: `where(due_date:
        # Date.current..)` becomes the day the process started and the tile shows
        # the wrong week until a redeploy. The reloader re-runs class bodies in
        # development, so it cannot reproduce there and is silent in production.
        # The block also runs against the widget, so it reaches `context` — a
        # frozen scope could never be tenant-scoped.
        def list(limit: PREVIEW_ROWS, &block)
          raise ArgumentError, "`list` needs a block: `list { Item.low_stock }`." unless block

          self._list = List.new(scope: block, limit: limit)
        end
      end

      # "3 left · Cocina". On `ListBase` rather than `Base` because every caller
      # is an `r.subtitle` block; an instance method so a row block —
      # `instance_exec`'d on the widget — can call it bare.
      def join(*parts) = Widget.join(*parts)

      # `check!` here as well as in `#items`, because a `:small` card renders no
      # rows and would otherwise never look: `count` would succeed, the hero would
      # print a confident number, and the widget would be broken at every other
      # size with nothing on screen saying so.
      def count
        @count ||= begin
          row_builder.check!(self.class)
          scope.count.to_i
        end
      end

      # A LIST'S COUNT REALLY IS A TALLY, so positive is the honest test here —
      # unlike the patterns whose `count` is a figure that can legitimately be
      # negative.
      def any? = count.positive?

      def display_value = Bali::Widget.abbreviate(count)

      def items
        @items ||= begin
          row_builder.check!(self.class)
          previewable.map { |record| row_builder.to_row(self, record) }
        end
      end

      private

      # ORDER THEN LIMIT: the scope carries its own `order` and `limit` is applied
      # after the block returns. An unordered scope previews whatever the database
      # happened to return, which is a different bug in every database.
      #
      # `scope`, not `list.scope` — the declaration is a Proc, and a Proc has no
      # `limit`.
      def previewable = scope.limit(list.limit)

      def list
        _list || raise(NotImplementedError,
                       "#{self.class.name || 'This widget'} must declare `list`.")
      end

      # The RELATION is memoised, never the rows: `count` and `items` issue two
      # different queries off it, which is what lets a card say "3 of 214".
      def scope = @scope ||= instance_exec(&list.scope)

      def row_builder
        _row_builder || raise(NotImplementedError,
                              "#{self.class.name || 'This widget'} must declare `row`.")
      end
    end
  end
end
