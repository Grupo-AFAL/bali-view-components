# frozen_string_literal: true

module Bali
  module Widget
    module List
      class Preview < ApplicationViewComponentPreview
        # How many, and which — the whole card for a `ListBase` widget.
        #
        # The card truncates to what its canvas has room for: a widget loads
        # `ListBase::PREVIEW_ROWS` regardless of the size it is drawn at, so raise
        # `rows` above the budget and watch the extra ones disappear rather than
        # overflow.
        #
        # @param size select { choices: [small, medium, large] }
        # @param rows number
        def default(size: :large, rows: 9)
          render Bali::Widget::List::Component.new(
            Bali::Widget::List::Preview.specimen(rows.to_i),
            region: Bali::Widget::Component.regions.fetch(size.to_sym)
          )
        end

        # A stand-in for a relation: the card only asks a scope to count and to
        # hand back a capped preview, so a preview needs no table.
        def self.specimen(rows)
          scope = Struct.new(:size) do
            def count = size
            def limit(n) = Array.new([ size, n ].min) { |i| { title: "Ingredient #{i + 1}" } }
          end.new(rows)

          Class.new(Bali::Widget::ListBase) do
            def self.key = "low_stock"
            title "Low stock items"
            short_title "Low stock"
            empty_message "Nothing running low"
          end.tap do |k|
            k.list { scope }
            k.row { |r| r.title { |item| item[:title] }; r.subtitle "In stock" }
          end.new
        end
      end
    end
  end
end
