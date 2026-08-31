# frozen_string_literal: true

module Bali
  module Widget
    # WHAT EVERY DECLARATION BLOCK YIELDS. `row`, `trend`, `goal`, `check` and
    # `series` each hand one of these to a class body, and each subclass adds
    # only its own setters — the two things they all did identically live here.
    #
    # Each setter writes its OWN ivar, so two blocks of the same kind MERGE per
    # field rather than the second replacing the first. That is what lets a
    # shared module declare what two widgets have in common while each declares
    # what differs.
    class Builder
      class << self
        # NAMES THE ONE DECLARATION A WIDGET CANNOT OMIT, so `check!` can say
        # which, in the spelling a host actually wrote:
        #
        #   requires "t.current", block: "trend"
        #
        # A pattern with nothing mandatory declares nothing and `check!` passes —
        # `series` is genuinely optional, and a widget with none renders no chart.
        def requires(declaration, block:)
          @required = declaration
          @required_block = block
        end

        attr_reader :required, :required_block
      end

      # CHECKED PER RENDER, not per row, and called from the pattern's PRIMARY
      # reader rather than only its richest one. A `:small` card renders no rows
      # and would otherwise never look: the hero would print a confident number
      # while the widget was broken at every other size.
      def check!(widget_class)
        return if self.class.required.nil? || declared?

        raise NotImplementedError,
              "#{widget_class.name || 'This widget'} must declare " \
              "`#{self.class.required}` in its `#{self.class.required_block}` block."
      end

      private

      # The field named by `requires`, read off its ivar. Overridden where nil or
      # false is a legitimate declared value and a sentinel is needed instead.
      def declared?
        !instance_variable_get(:"@#{self.class.required.split('.').last}").nil?
      end

      # A BLOCK runs against the WIDGET, so it reaches `context`, route helpers
      # and private methods; anything else is the value itself, which is what
      # lets a fixed series be written `s.values [ 1, 2, 3 ]`.
      def resolve(widget, field)
        field.is_a?(Proc) ? widget.instance_exec(&field) : field
      end
    end
  end
end
