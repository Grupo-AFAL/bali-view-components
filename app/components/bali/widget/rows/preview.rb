# frozen_string_literal: true

module Bali
  module Widget
    module Rows
      class Preview < ApplicationViewComponentPreview
        # A list widget's preview rows, already truncated to what the canvas has
        # room for.
        #
        # Turn `long_titles` on to see the truncation the `min-w-0` exists for: a
        # flex item's default `min-width:auto` refuses to shrink below its
        # content, so without it a long title pushes through the card's edge
        # instead of being cut.
        #
        # @param count number
        # @param long_titles toggle
        # @param linked toggle
        def default(count: 3, long_titles: false, linked: true)
          rows = Array.new(count.to_i) do |i|
            Bali::Widget::ListBase::Row.new(
              title: long_titles ? "An ingredient with a name far too long for one line #{i + 1}" : "Ingredient #{i + 1}",
              subtitle: Bali::Widget.join("#{i + 1} left", "Cocina"),
              href: linked ? "/lookbook" : nil
            )
          end

          render Bali::Widget::Rows::Component.new(rows)
        end
      end
    end
  end
end
