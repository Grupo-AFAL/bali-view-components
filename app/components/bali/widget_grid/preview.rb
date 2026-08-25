# frozen_string_literal: true

module Bali
  module WidgetGrid
    class Preview < ApplicationViewComponentPreview
      # Widgets with no host behind them, one per size, so the bento shows all
      # four spans at once.
      class Demo < Bali::Widget::Base
        # `define_singleton_method(:key) { key }` is NOT infinite recursion: the
        # block closes over `build`'s local parameter, which shadows the method
        # being defined. The override is required rather than decorative —
        # `Base.key` derives from `name.demodulize.underscore`, and an anonymous
        # `Class.new` has no `name`, so without it every call raises.
        def self.build(key, size, count)
          Class.new(self) do
            sized size
            define_singleton_method(:key) { key }
            define_singleton_method(:title) { key.humanize }
            define_singleton_method(:short_title) { key.humanize }
            define_singleton_method(:empty_message) { "Nothing here" }
            define_method(:call) do
              Bali::Widget::Result.new(
                count: count,
                view_all_path: "/lookbook",
                items: Array.new(count) { |i| Bali::Widget::Row.new(title: "Row #{i + 1}") }
              )
            end
          end.new
        end
      end

      SPECIMENS = [
        [ "overdue_counts", :small, 4 ],
        [ "low_stock_items", :medium, 6 ],
        [ "expiring_stock", :large, 9 ],
        [ "cost_spikes", :wide, 3 ]
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
                               widgets: Bali::WidgetGrid::Preview::SPECIMENS.map do |key, size, count|
                                 Bali::WidgetGrid::Preview::Demo.build(key, size, count)
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
