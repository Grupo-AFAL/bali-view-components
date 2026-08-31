# frozen_string_literal: true

module Bali
  module Widget
    # ONE FIGURE, and nothing else. The simplest ladder: a number and its label,
    # on a tile you can read at a glance.
    #
    #   class ProductionBudget < Bali::Widget::ValueBase
    #     default_size :small
    #
    #     value { Movie.budgeted.sum(:budget).to_i }
    #     display_value { "$#{Bali::Widget.abbreviate(value)}" }
    #   end
    #
    # TWO FLAT DECLARATIONS rather than a builder block, because this is the one
    # pattern that builds no value object. `list` yields a builder because a
    # collection has knobs; `trend` and `goal` because they assemble a `Trend` and
    # a `Goal`. A figure assembles nothing, so there is nothing to group.
    #
    # `supports :small` by default, and that is the point of the class rather
    # than a limitation of it: a bare figure at `large` is a title, a number and
    # most of a 2x2 cell of whitespace. Say `supports` yourself to override.
    class ValueBase < Base
      supports :small

      class_attribute :_value, **ATTRIBUTE_OPTIONS
      class_attribute :_display_value, **ATTRIBUTE_OPTIONS

      class << self
        # THE FIGURE. A block is `instance_exec`'d on the WIDGET, so it reaches
        # `context` and private methods; anything else is the value itself.
        def value(value = nil, &block)
          unless value || block
            raise ArgumentError, "`value` needs a figure: `value { Item.count }`."
          end

          self._value = block || value
        end

        # What the headline PRINTS, when the number is not the display. A ~215px
        # tile at `text-4xl` fits four to six characters, so `Widget.abbreviate`
        # is usually part of the answer. The block reads `value`.
        def display_value(value = nil, &block) = self._display_value = block || value
      end

      # A READER over the declaration, memoised — `count` reads it, and so does
      # any `display_value` block.
      #
      # THE SAME WORD AS THE MACRO ABOVE, deliberately: `value { … }` in a class
      # body is the class method, and a bare `value` anywhere else — including
      # inside `display_value { "$#{Widget.abbreviate(value)}" }` — is this one.
      # The alternative was a second
      # name for one concept, which reads worse in the class body where hosts
      # actually work.
      def value
        return @value if defined?(@value)

        unless _value
          raise NotImplementedError,
                "#{self.class.name || 'This widget'} must declare `value`."
        end

        @value = _value.is_a?(Proc) ? instance_exec(&_value) : _value
      end

      # `value` IS the count as far as the card is concerned — that is what makes
      # the empty state and the "view all" link work without a second reader.
      def count = @count ||= value.to_i

      # WHAT THE HEADLINE PRINTS. Wrapped here rather than by a hook on `Base`,
      # because everything a host writes has to run inside the failure net and
      # the declaration is host code — a raising format degrades this tile
      # instead of taking the page down.
      #
      # Falls back to the abbreviated count, which is what the card would
      # printed anyway; declaring `display_value` is for when the number is not
      # the display.
      def display_value
        return Widget.abbreviate(count) if _display_value.nil?

        _display_value.is_a?(Proc) ? instance_exec(&_display_value) : _display_value
      end
    end
  end
end
