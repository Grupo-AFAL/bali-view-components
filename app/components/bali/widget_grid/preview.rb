# frozen_string_literal: true

module Bali
  module WidgetGrid
    class Preview < ApplicationViewComponentPreview
      # Specimens with no host behind them, one per pattern and one per size, so
      # the bento shows the whole matrix at once. THE PATTERN IS THE TYPE, so
      # each is built from the base class its ladder belongs to.
      module Demo
        # `define_singleton_method(:key)` is NOT infinite recursion: the block
        # closes over the local parameter, which shadows the method being
        # defined. It is required rather than decorative — `Base.key` derives
        # from `name.demodulize.underscore`, and an anonymous `Class.new` has no
        # `name`, so without it every call raises.
        def self.named(base, key, size, &block)
          Class.new(base) do
            define_singleton_method(:key) { key }
            title key.humanize
            short_title key.humanize
            empty_message "Nothing here"
            view_all_path { "/lookbook" }
            class_eval(&block)
            default_size size
          end.new
        end

        def self.list(key, size, count)
          rows = Rows.new(count)

          named(Bali::Widget::ListBase, key, size) do
            row do |r|
              r.title { |row| row[:title] }
            end
            define_method(:count) { count }
            # The local, not `Rows.new(count)` — a `list` block is instance_exec'd
            # against the widget, where `count` is the widget's own reader.
            list { rows }
          end
        end

        def self.trend(key, size, count)
          named(Bali::Widget::TrendBase, key, size) do
            trend do |t|
              t.current { count }
              t.previous { [ count / 2, 1 ].max }
              t.positive_when :down
              t.period_label "vs last week"
            end
            series do |s|
              s.labels { %w[Mon Tue Wed Thu Fri Sat Sun] }
              s.values { [ 3, 5, 4, 8, 6, 9, 12 ] }
            end
          end
        end

        def self.goal(key, size, count)
          named(Bali::Widget::ProgressBase, key, size) do
            goal do |g|
              g.value { count }
              g.max 10
              g.label "of 10"
            end
            series do |s|
              s.labels { %w[Mon Tue Wed Thu Fri Sat Sun] }
              s.values { [ 2, 4, 3, 6, 5, 7, 9 ] }
            end
          end
        end

        # A stand-in for a relation: the card only asks a scope to count and to
        # hand back a capped preview, so a preview needs no table.
        Rows = Struct.new(:size) do
          def count = size
          def order(*) = self
          def limit(n) = Array.new([ size, n ].min) { |i| { title: "Row #{i + 1}" } }
        end
      end

      # One per pattern and one per size, so the grid shows the whole matrix.
      SPECIMENS = [
        [ :trend, "overdue_counts", :small, 4 ],
        [ :trend, "low_stock_items", :medium, 6 ],
        [ :list, "expiring_stock", :large, 9 ],
        [ :goal, "cost_spikes", :large, 7 ]
      ].freeze

      # A user-arrangeable dashboard. Press **Edit** to reveal each card's handle,
      # remove button and size picker; drag a card, or focus a handle and use the
      # arrow keys.
      #
      # Every gesture PATCHes the whole layout to `url`. Bali ships no controller
      # and no routes — who may see which widget is the host's rule — so a host
      # writes roughly:
      #
      # ```ruby
      # def update
      #   layout.arrange(permitted_layout)   # permitted_layout looks each key up
      #   head :no_content                   # in the ALREADY-AUTHORIZED set
      # end
      # ```
      #
      # The dummy app behind this preview is a stub that only answers `204`, so
      # rearranging here will not survive a reload. See `docs/guides/engine-models.md`
      # for the version worth copying.
      #
      # @param add_tile toggle
      def default(add_tile: true)
        render_with_template(locals: {
                               widgets: Bali::WidgetGrid::Preview::SPECIMENS.map do |pattern, key, size, count|
                                 Bali::WidgetGrid::Preview::Demo.public_send(pattern, key, size, count)
                               end,
                               add_path: add_tile ? "/lookbook" : nil
                             })
      end

      # The three extension points `default` never shows: a custom `heading` (which
      # replaces the hint but CANNOT remove the Edit control), a widget filling the
      # card's `body` slot instead of rendering a list, and — with `populated` off —
      # the empty state, including the "Add widget" CTA that only appears when the
      # host passed an `add_path`.
      #
      # @param populated toggle
      def with_slots(populated: true)
        render_with_template(locals: { populated: populated })
      end
    end
  end
end
