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
    # The connector under each circle takes the state of the *next* step, so the
    # line "arrives" coloured at the step that owns that verdict. That is
    # computed here, not by the caller.
    #
    # Auto-numbering counts the real route only: a `:skipped` step renders
    # without a number and consumes no position. An explicit `number:` always
    # wins.
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
    class Component < ApplicationViewComponent
      BASE_CLASSES = "workflow-steps"

      renders_many :steps, lambda { |title:, state:, number: nil, **options|
        step = Step::Component.new(
          title: title,
          state: state,
          number: number || next_auto_number(state),
          **options
        )
        tracked_steps << step
        step
      }

      # @param options [Hash] HTML attributes for the `<ol>` container
      def initialize(**options)
        @options = options
        @auto_number = 0
      end

      private

      attr_reader :options

      # Each connector is painted with the state of the step it leads to, so
      # the pairing can only happen once every step is declared. That is NOT
      # `before_render`: slot blocks evaluate lazily, on the first access to a
      # slot getter, which `before_render` runs before. Reading `steps` first
      # forces that evaluation; the slots themselves render later, in the
      # template, after the mutation. The last step keeps `connector_state`
      # nil and draws no connector.
      def paired_steps
        slots = steps
        tracked_steps.each_cons(2) do |step, next_step|
          step.connector_state = next_step.state
        end
        slots
      end

      # The slot machinery wraps each step; this keeps the component instances
      # reachable for the connector pairing in #before_render.
      def tracked_steps
        @tracked_steps ||= []
      end

      # A skipped step is off the real route, so it takes no position. State
      # validation happens in Step::Component; an invalid or nil state raises
      # there, so here nil only needs to not blow up first.
      def next_auto_number(state)
        return nil if state.nil? || state.to_sym == Step::Component::SKIPPED

        @auto_number += 1
      end

      def component_classes
        class_names(BASE_CLASSES, options[:class])
      end

      def container_options
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
