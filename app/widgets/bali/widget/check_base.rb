# frozen_string_literal: true

module Bali
  module Widget
    # DOES IT PASS? One fact with two answers and a third for "not yet known".
    #
    #   class BackupsHealthy < Bali::Widget::CheckBase
    #     default_size :small
    #
    #     check do |c|
    #       c.value { Backup.last&.succeeded? }
    #       c.pass "Healthy"
    #       c.fail "Failing"
    #     end
    #   end
    #
    # TERNARY, NOT BOOLEAN. `nil` is "not checked yet" and renders muted, which is
    # a different statement from a failing check — the same distinction
    # `Bali::BooleanIcon` already draws, and this pattern renders through that
    # component rather than restating it.
    #
    # THE NAME CARRIES THE POLARITY, which is why there is no `positive_when` here
    # as there is on `TrendBase`. A trend's number has none of its own — 12% up is
    # neutral until you say what it measures — so it must be declared. A check's
    # name states it: "Backups healthy", "Certificate valid", "Queue draining".
    # Phrase the check so TRUE IS GOOD and the card colours itself.
    #
    # `supports :small` by default, for `ValueBase`'s reason: a check is one fact,
    # and there is nothing to fill a 2x2 with. Declare `supports` yourself if you
    # have a subtitle worth the room.
    class CheckBase < Base
      supports :small

      # What `check` yields. Each setter writes its OWN ivar, so two `check`
      # blocks merge per field — see the builder contract on `Base`.
      class CheckBuilder < Builder
        requires "c.value", block: "check"
        # `block || value` — the idiom every other builder uses — cannot work
        # here: `false` and `nil` are the two answers this pattern exists to
        # carry, and both are falsy, so a declared `c.value false` would read as
        # no declaration at all. A sentinel distinguishes "not declared" from
        # "declared false".
        UNSET = Object.new.freeze
        private_constant :UNSET

        def initialize
          @value = UNSET
        end

        # A block is `instance_exec`'d on the WIDGET, so it reaches `context` and
        # private methods; anything else is the value itself.
        def value(value = UNSET, &block) = @value = block || value

        # What the tile says under the icon. Both default to the shared Bali
        # wording, so a check that needs no custom copy declares only its value.
        def pass(value = nil, &block) = @pass = block || value

        def fail(value = nil, &block) = @fail = block || value

        # `nil` stays `nil`; anything else collapses to a boolean, so a truthy
        # non-boolean reads as true — `BooleanIcon`'s own rule.
        def resolved_value(widget)
          answer = resolve(widget, @value)

          answer.nil? ? nil : !!answer
        end

        def label(widget, passing)
          declared = passing ? @pass : @fail
          return resolve(widget, declared) if declared

          I18n.t("bali_view.widgets.check.#{passing ? 'pass' : 'fail'}")
        end

        private

        # A SENTINEL, not nil: `c.value false` is a widget reporting a real
        # failing check, and `@value.nil?` would read it as never declared.
        def declared? = !@value.equal?(UNSET)
      end
      private_constant :CheckBuilder

      # THE ANSWER, AND ITS TWO LABELS.
      declares :check, hint: "check { |c| c.value { Thing.ok? } }" do
        CheckBuilder.new
      end

      # The answer: `true`, `false`, or `nil` for not yet known. Validated here
      # rather than only in `#state`, because `count` reads this and the card
      # reads `count` at every size.
      def passing?
        return @passing if defined?(@passing)

        check_builder.check!(self.class)
        @passing = check_builder.resolved_value(self)
      end

      # 1 once the check HAS an answer, either way. A failing check is not an
      # empty one, and `count.positive?` is what drives the card's muted
      # "nothing here" treatment and its "view all" link.
      def count = @count ||= passing?.nil? ? 0 : 1

      # What the card prints beside the icon. Inside the net, because the labels
      # are host code.
      def display_value = check_builder.label(self, passing?)

      # PASSING, FAILING, OR NOT YET KNOWN. A failing check is an answer, not an
      # absence — only `nil` is nothing.
      def any? = !passing?.nil?

      private

      def check_builder
        _check_builder || raise(NotImplementedError,
                                "#{self.class.name || 'This widget'} must declare `check`.")
      end
    end
  end
end
