# frozen_string_literal: true

module Bali
  module Widget
    # WHAT EVERY DECLARATION BLOCK YIELDS — `row`, `trend`, `goal`, `check`,
    # `series`. Each subclass adds only its own setters.
    #
    # EACH SETTER WRITES ITS OWN IVAR, so two blocks of the same kind MERGE per
    # field rather than the second replacing the first — which lets a shared
    # module declare what two widgets have in common while each declares what
    # differs. Every builder inherits this; none of them restates it.
    class Builder
      class << self
        # The one declaration a widget cannot omit, in the spelling a host wrote:
        # `requires "t.current", block: "trend"`. A pattern with nothing mandatory
        # declares nothing and `check!` passes.
        def requires(declaration, block:)
          @required = declaration
          @required_block = block
        end

        attr_reader :required, :required_block
      end

      # Called from the pattern's PRIMARY reader, not only its richest one: a
      # `:small` card renders no rows and would otherwise never look, printing a
      # confident number for a widget broken at every other size.
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
      # and private methods; anything else is the value itself.
      def resolve(widget, field)
        field.is_a?(Proc) ? widget.instance_exec(&field) : field
      end
    end
  end
end
