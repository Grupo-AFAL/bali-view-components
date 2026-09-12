# frozen_string_literal: true

module Bali
  module Filters
    module CombinatorDivider
      # Divider with the AND/OR toggle rendered between filter groups. Extracted
      # because the popover and inline branches of `Filters::Component` carried
      # the same markup twice.
      #
      # The markup mirrors `createCombinatorDivider` in
      # `filters/controllers/filters_controller.js` (the copy for groups added
      # client-side); the root keeps the `flex` class because `removeGroup`
      # identifies dividers by it when deleting adjacent siblings.
      class Component < ApplicationViewComponent
        attr_reader :combinator

        # @param combinator [String] "and" or "or" - the currently-applied group combinator
        def initialize(combinator:)
          @combinator = combinator
        end
      end
    end
  end
end
