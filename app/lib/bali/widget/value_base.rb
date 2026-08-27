# frozen_string_literal: true

module Bali
  module Widget
    # ONE FIGURE, and nothing else. The simplest ladder: a number and its label,
    # on a tile you can read at a glance.
    #
    #   class ProductionBudget < Bali::Widget::ValueBase
    #     default_size :small
    #
    #     def value = Movie.budgeted.sum(:budget).to_i
    #     def display_value = "$#{Bali::Widget.abbreviate(value)}"
    #   end
    #
    # `supports :small` by default, and that is the point of the class rather
    # than a limitation of it: a bare figure at `large` is a title, a number and
    # most of a 2x2 cell of whitespace. Say `supports` yourself to override.
    class ValueBase < Base
      self._supported_sizes = [ SIZES.first ].freeze

      # The figure. Whatever the card shows big.
      def value
        raise NotImplementedError, "#{self.class.name || 'This widget'} must define `#value`."
      end

      # `value` IS the count as far as the card is concerned — that is what makes
      # the empty state and the "view all" link work without a second reader.
      def count = safely(0) { value.to_i }
    end
  end
end
