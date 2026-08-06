# frozen_string_literal: true

module Bali
  module WorkflowSteps
    # Steps of a flow with a verdict per step.
    #
    # `Stepper` is a wizard by index: one `current:` and every step derives its
    # look from its position. `WorkflowSteps` is positional too, but each step
    # carries its own semantic state — an approval chain where step 2 was
    # rejected while step 4 is still pending cannot be told with an index.
    #
    # Two shapes over the same steps:
    #
    #   :vertical (default)  the record — numbered circle, coloured connector,
    #                        assignee, date and comment per step.
    #   :horizontal          the quick flow — a row of cards with a state dot
    #                        and an N/M bar on top, for the summary card or the
    #                        table cell where the whole chain has to fit in a
    #                        glance.
    #
    # In the vertical shape the connector under each circle takes the state of
    # the *next* step, so the line "arrives" coloured at the step that owns that
    # verdict. That is computed here, not by the caller. The horizontal shape
    # draws no connectors: the bar already says how far the flow got.
    #
    # Auto-numbering counts the real route only: a `:skipped` step renders
    # without a number and consumes no position. An explicit `number:` always
    # wins. Neither reaches the horizontal shape, whose marker is a dot.
    #
    # @example An approval chain
    #   render Bali::WorkflowSteps::Component.new do |c|
    #     c.with_step(title: 'Submitted', state: :success, assignee: 'Luis Pérez', date: 'Jul 1')
    #     c.with_step(title: 'Legal review', state: :error, assignee: 'Ana Gutiérrez') do
    #       'Rejected: missing appendix B.'
    #     end
    #     c.with_step(title: 'Finance sign-off', state: :skipped)
    #     c.with_step(title: 'Director signature', state: :pending)
    #   end
    #
    # @example The same chain as a quick flow
    #   render Bali::WorkflowSteps::Component.new(variant: :horizontal) do |c|
    #     c.with_step(title: 'Submitted', state: :success)
    #     c.with_step(title: 'Legal review', state: :current)
    #     c.with_step(title: 'Director signature', state: :pending)
    #   end
    #
    class Component < ApplicationViewComponent
      BASE_CLASSES = "workflow-steps"

      # The variant is a class on the root rather than a different element
      # name: the stylesheet keys the whole structure off it, and a host that
      # needs to target one shape has something to write.
      VARIANT_CLASSES = {
        vertical: "workflow-steps-vertical",
        horizontal: "workflow-steps-horizontal"
      }.freeze

      VARIANTS = VARIANT_CLASSES.keys.freeze

      # What the N of the N/M bar counts: steps with a verdict, which are not
      # going to change again. `:skipped` is one of them — a step the route
      # left out is settled, and it is still one of the dots on screen, so
      # counting it keeps N/M matching what the reader can count. `:pending`
      # and `:current` are the two that have not happened yet.
      TERMINAL_STATES = %i[success error warning skipped].freeze

      # The bar takes the flow's verdict, worst state first: a chain someone
      # rejected reads red at a glance, which is the whole point of a quick
      # flow. Anything else is neutral progress.
      PROGRESS_COLORS = { error: :error, warning: :warning }.freeze

      renders_many :steps, lambda { |title:, state:, number: nil, **options|
        step = Step::Component.new(
          title: title,
          state: state,
          number: number || next_auto_number(state),
          dot: horizontal?,
          **options
        )
        tracked_steps << step
        step
      }

      # @param variant [Symbol] `:vertical` (default) or `:horizontal`
      # @param progress [Boolean, nil] The N/M bar. On by default in the
      #   horizontal variant, which is the only shape with a header for it.
      # @param options [Hash] HTML attributes for the root element
      def initialize(variant: :vertical, progress: nil, **options)
        @variant = validated_variant(variant)
        @progress = validated_progress(progress)
        @options = options
        @auto_number = 0
      end

      private

      attr_reader :variant, :options

      def horizontal?
        variant == :horizontal
      end

      # A bar over no steps says nothing, and `<progress max="0">` is not valid
      # HTML anyway.
      def progress?
        @progress && total_count.positive?
      end

      # `Color.name!` reads nil as "not given", which for a variant means the
      # default rather than an error — unlike a step's state, this one has a
      # sane default to fall back to.
      def validated_variant(value)
        Bali::Color.name!(self.class.name, value, param: :variant, allowed: VARIANTS) || :vertical
      end

      # The bar is part of the quick-flow header, and the vertical shape has no
      # header to hang it on. Asking for one there is a request this component
      # cannot honour, so it says so instead of dropping it silently. `false`
      # asks for nothing, so it stays legal on both.
      def validated_progress(value)
        return horizontal? if value.nil?
        return value if horizontal? || !value

        raise ArgumentError,
              "#{self.class.name}: progress: true needs variant: :horizontal. " \
              "The N/M bar belongs to the quick-flow header; the vertical variant has none."
      end

      # Each connector is painted with the state of the step it leads to, so
      # the pairing can only happen once every step is declared. That is NOT
      # `before_render`: slot blocks evaluate lazily, on the first access to a
      # slot getter, which `before_render` runs before. Reading `steps` first
      # forces that evaluation; the slots themselves render later, in the
      # template, after the mutation. The last step keeps `connector_state`
      # nil and draws no connector.
      def rendered_steps
        @rendered_steps ||= begin
          slots = steps
          pair_connectors unless horizontal?
          slots
        end
      end

      def pair_connectors
        tracked_steps.each_cons(2) do |step, next_step|
          step.connector_state = next_step.state
        end
      end

      # The step components behind the slots, with every slot block already
      # evaluated. The progress header renders *before* the list, and a slot
      # nobody has read yet is a step these counts cannot see.
      def declared_steps
        rendered_steps
        tracked_steps
      end

      # The slot machinery wraps each step; this keeps the component instances
      # reachable for the connector pairing and for the N/M counts.
      def tracked_steps
        @tracked_steps ||= []
      end

      def resolved_count
        declared_steps.count { |step| TERMINAL_STATES.include?(step.state) }
      end

      def total_count
        declared_steps.size
      end

      def progress_color
        worst = PROGRESS_COLORS.keys.find do |state|
          declared_steps.any? { |step| step.state == state }
        end

        PROGRESS_COLORS.fetch(worst, :primary)
      end

      # A skipped step is off the real route, so it takes no position. State
      # validation happens in Step::Component; an invalid or nil state raises
      # there, so here nil only needs to not blow up first.
      def next_auto_number(state)
        return nil if state.nil? || state.to_sym == Step::Component::SKIPPED

        @auto_number += 1
      end

      def component_classes
        class_names(BASE_CLASSES, VARIANT_CLASSES.fetch(variant), options[:class])
      end

      def container_options
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
