# frozen_string_literal: true

module Bali
  module Widget
    module SizePicker
      class Preview < ApplicationViewComponentPreview
        # The size chooser from a widget card's edit shelf, on its own so its
        # keyboard contract can be exercised without a dashboard around it.
        #
        # It is a real radiogroup: one tab stop for the whole set, all four
        # arrows moving within it (wrapping), Home and End jumping to the ends,
        # and selection following focus. The arrows are wired to
        # `WidgetGridController#sizeKeydown`, so they only move inside a grid —
        # here, Tab reaches the checked size and Space selects.
        #
        # @param size select { choices: [small, medium, large, wide] }
        def default(size: :medium)
          render Bali::Widget::SizePicker::Component.new(size: size, title: "Low stock")
        end
      end
    end
  end
end
