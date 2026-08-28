# frozen_string_literal: true

module Bali
  module Widget
    # PROGRESS TOWARD A GOAL, and how you got there.
    #
    #   class ProjectProgress < Bali::Widget::ProgressBase
    #     default_size :large
    #
    #     goal do |g|
    #       g.value { Task.where(status: :done).count }
    #       g.max   { Task.count }
    #       g.label { "of #{max}" }
    #     end
    #
    #     series { |s| s.values { Task.group(:status).count.values } }
    #   end
    #
    # The ring REPLACES the number as the headline, which is what makes this a
    # different pattern rather than a list with a decoration.
    class ProgressBase < Base
      include Charted

      # A breakdown rather than a movement over time, so bars rather than a line.
      self._default_series_type = :bar

      Goal = Data.define(:value, :max, :label) do
        def initialize(value:, max: 100, label: nil) = super

        # CLAMPED for drawing only: 11 of 10 shifts covered is a real and good
        # state that a ring has nowhere to put, so `value` still reads true.
        # A `max` of zero is "no goal set" — a configuration state, not an error,
        # and dividing by it would take a page down over one misconfiguration.
        def percentage
          return 0.0 if max.to_f.zero?

          (value.to_f / max.to_f * 100).clamp(0.0, 100.0)
        end
      end

      # What `goal` yields — everything the ring is drawn from. Each setter writes
      # its OWN ivar, so two `goal` blocks merge per field.
      class GoalBuilder
        # A block is `instance_exec`'d on the WIDGET, so it reaches `context` and
        # private methods; anything else is the value itself.
        def value(value = nil, &block) = @value = block || value

        def max(value = nil, &block) = @max = block || value

        # Reads `max` off the widget, not off `g` — `ProgressBase#max` resolves
        # this builder, so `g.label { "of #{max}" }` sees the same figure the ring
        # is drawn to.
        def label(value = nil, &block) = @label = block || value

        # READS THROUGH THE WIDGET, never through `resolved_value`/`resolved_max`.
        # That is the invariant that makes `g.label { "of #{max}" }` print the
        # same figure the ring is drawn to: the widget's readers memoise, these
        # do not, and shortcutting to them here would run each block a second
        # time and could disagree with the label.
        def to_goal(widget)
          Goal.new(value: widget.value, max: widget.max, label: resolve(widget, @label))
        end

        def resolved_value(widget) = resolve(widget, @value)

        # 100 by default, so a widget whose figure is already a percentage
        # declares `g.value` alone.
        def resolved_max(widget) = @max.nil? ? 100 : resolve(widget, @max)

        def check!(widget_class)
          return if @value

          raise NotImplementedError,
                "#{widget_class.name || 'This widget'} must declare `g.value` in its `goal` block."
        end

        private

        def resolve(widget, field)
          field.is_a?(Proc) ? widget.instance_exec(&field) : field
        end
      end
      private_constant :GoalBuilder

      class_attribute :_goal_builder, **ATTRIBUTE_OPTIONS

      class << self
        # THE RING'S CAPTION. Optional — a ring with no label still draws its
        # percentage.
        #
        # DUPS what it inherits, for the same reason `row` and `series` do.
        def goal(&block)
          raise ArgumentError, "`goal` needs a block: `goal { |g| g.value { Item.done.count } }`." unless block

          self._goal_builder = _goal_builder&.dup || GoalBuilder.new
          block.call(_goal_builder)
        end
      end

      # How far along, and what counts as done. READERS over the declaration
      # rather than methods a host overrides — but still methods, because
      # `g.label { "of #{max}" }` has to be able to read one.
      #
      # Memoised: the ring reads both, `count` reads `value` again, and a
      # declaration doing real work should not do it three times.
      # `defined?` rather than `||=`, so a legitimately nil or zero figure is
      # memoised rather than re-read on every call.
      # CHECKS HERE, not only in `#goal` — `count` reads this and the card always
      # reads `count`, so a missing `g.value` degrades the tile at every size.
      # Guarding only `#goal` left the hero card printing a confident blank.
      def value
        return @value if defined?(@value)

        goal_builder.check!(self.class)
        @value = goal_builder.resolved_value(self)
      end

      def max
        return @max if defined?(@max)

        @max = goal_builder.resolved_max(self)
      end

      # The ring is the headline, but `count` still gates the empty state and the
      # "view all" link, so it answers with what has been achieved.
      def count = @count ||= value.to_i

      # Memoised: the card asks `goal?` and then renders `goal.to_h`.
      def goal
        return @goal if defined?(@goal)

        goal_builder.check!(self.class)
        @goal = goal_builder.to_goal(self)
      end


      private

      def goal_builder
        _goal_builder || raise(NotImplementedError,
                               "#{self.class.name || 'This widget'} must declare `goal`.")
      end
    end
  end
end
