# frozen_string_literal: true

module Bali
  module WidgetGrid
    class Preview < ApplicationViewComponentPreview
      # Widgets with no host behind them, one per size, so the bento shows all
      # four spans at once.
      class Demo < Bali::Widget::Base
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
      # Every gesture PATCHes the whole layout to `url` — Bali ships no controller,
      # so this preview points at the dummy app's:
      #
      # ```ruby
      # def update
      #   layout.arrange(permitted_layout)
      #   head :no_content
      # end
      # ```
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
    end
  end
end
