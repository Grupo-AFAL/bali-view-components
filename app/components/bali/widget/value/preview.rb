# frozen_string_literal: true

module Bali
  module Widget
    module Value
      class Preview < ApplicationViewComponentPreview
        # A figure, and nothing else — the whole card for a `ValueBase` widget.
        #
        # `size` picks the canvas the card is drawn on — the region it is handed
        # decides the layout, not the card.
        #
        # @param size select { choices: [small, medium, large] }
        # @param value number
        def default(size: :medium, value: 1_234_567)
          render Bali::Widget::Value::Component.new(
            Class.new(Bali::Widget::ValueBase) do
              def self.key = "budget"
              title "Production budget"
              short_title "Budget"
              empty_message "Nothing recorded"
              supports(*Bali::Widget::SIZES)
            end.tap { |k| k.value { value.to_i } }.new,
            region: Bali::Widget::Component.regions.fetch(size.to_sym)
          )
        end
      end
    end
  end
end
