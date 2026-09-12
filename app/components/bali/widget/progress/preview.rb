# frozen_string_literal: true

module Bali
  module Widget
    module Progress
      class Preview < ApplicationViewComponentPreview
        # Progress toward a goal. Push `value` past `max` to see the clamp: the arc
        # stops at full while the label still reports the true figure, because 11
        # of 10 shifts covered is a real and good state a ring cannot draw. Set
        # `max` to 0 for "no goal set" — configuration, not an error.
        #
        # `size` picks the canvas the card is drawn on.
        #
        # @param size select { choices: [small, medium, large] }
        # @param value number
        # @param max number
        def default(size: :medium, value: 7, max: 10)
          render Bali::Widget::Progress::Component.new(
            Class.new(Bali::Widget::ProgressBase) do
              def self.key = "onboarding"
              title "Onboarding"
              short_title "Onboarding"
              empty_message "Nothing to track"
            end.tap { |k| k.goal { |g| g.value value.to_i; g.max max.to_i; g.label "of #{max}" } }.new,
            size: size.to_sym
          )
        end
      end
    end
  end
end
