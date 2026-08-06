# frozen_string_literal: true

module Bali
  module WorkflowSteps
    module Step
      # One step of a workflow: numbered circle, connector to the next step,
      # title, and the optional assignee / date / free comment block.
      #
      # `connector_state` is written by the parent in its `before_render` — it
      # is the state of the step that FOLLOWS this one, or nil on the last step.
      class Component < ApplicationViewComponent
        SKIPPED = :skipped

        # Literal class tables, like `Stepper::Step::COLORS`: Tailwind's source
        # scanner only sees classes written out in full in this file.
        CIRCLE_CLASSES = {
          success: "bg-success text-success-content",
          error: "bg-error text-error-content",
          warning: "bg-warning text-warning-content",
          pending: "bg-base-300 text-base-content/60",
          skipped: "bg-base-200 text-base-content/40",
          current: "bg-primary text-primary-content ring-2 ring-primary/40 " \
                   "ring-offset-2 ring-offset-base-100"
        }.freeze

        CONNECTOR_CLASSES = {
          success: "bg-success",
          error: "bg-error",
          warning: "bg-warning",
          pending: "bg-base-300",
          skipped: "bg-base-300",
          current: "bg-primary"
        }.freeze

        STATES = CIRCLE_CLASSES.keys.freeze

        # Steps that have not happened read muted, like the rest of their row.
        MUTED_TITLE_STATES = %i[pending skipped].freeze

        attr_reader :title, :state, :number, :assignee, :date
        attr_accessor :connector_state

        # @param title [String] The step's name
        # @param state [Symbol] One of STATES
        # @param number [Integer, String, nil] Circle content; nil renders a dash
        # @param assignee [String, nil] Who the step belongs to
        # @param date [String, nil] Preformatted date/time text
        # @param options [Hash] HTML attributes for the `<li>`
        def initialize(title:, state:, number: nil, assignee: nil, date: nil, **options)
          @title = title
          @state = validated_state(state)
          @number = number
          @assignee = assignee
          @date = date
          @options = options
          @connector_state = nil
        end

        def skipped?
          state == SKIPPED
        end

        private

        attr_reader :options

        # `Color.name!` treats nil as "no colour", which is right for optional
        # colours and wrong for a required state — reject it before it can
        # surface later as a KeyError deep in the class tables.
        def validated_state(state)
          Bali::Color.name!(self.class.name, state, param: :state, allowed: STATES) ||
            raise(ArgumentError,
                  "#{self.class.name}: state is required. " \
                  "Valid: #{STATES.map(&:inspect).join(', ')}.")
        end

        def step_classes
          class_names("workflow-step", options[:class])
        end

        def step_options
          options.except(:class).merge(class: step_classes)
        end

        def circle_classes
          class_names("workflow-step-circle", CIRCLE_CLASSES.fetch(state))
        end

        def connector_classes
          class_names("workflow-step-connector", CONNECTOR_CLASSES.fetch(connector_state))
        end

        def title_classes
          class_names(
            "workflow-step-title",
            "text-base-content/40" => MUTED_TITLE_STATES.include?(state)
          )
        end
      end
    end
  end
end
