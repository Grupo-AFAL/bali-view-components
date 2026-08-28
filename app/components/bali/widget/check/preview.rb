# frozen_string_literal: true

module Bali
  module Widget
    module Check
      class Preview < ApplicationViewComponentPreview
        # Does it pass? TERNARY on purpose: `unknown` is a third state, not a
        # failure. A check with no answer yet draws muted, which says something
        # different from one that answered no — and the label is printed AND
        # announced, so a screen reader hears the widget's own words.
        #
        # `size` picks the canvas the card is drawn on — the region it is handed
        # decides the layout, not the card.
        #
        # @param size select { choices: [small, medium, large] }
        # @param state [Symbol] select [pass, fail, unknown]
        def default(size: :medium, state: :pass)
          render Bali::Widget::Check::Component.new(
            Class.new(Bali::Widget::CheckBase) do
              def self.key = "backups"
              title "Backups healthy"
              short_title "Backups"
              empty_message "Nothing to check"
              supports(*Bali::Widget::SIZES)
            end.tap do |k|
              k.check do |c|
                c.value({ pass: true, fail: false, unknown: nil }.fetch(state.to_sym))
                c.pass "Healthy"
                c.fail "Failing"
              end
            end.new,
            region: Bali::Widget::Component.regions.fetch(size.to_sym)
          )
        end
      end
    end
  end
end
