# frozen_string_literal: true

module Bali
  module WorkflowSteps
    module Step
      # One step of a workflow: a marker, the title, and the optional assignee
      # / date / free comment block.
      #
      # The marker is the only thing the four shapes disagree on, and `marker:`
      # is which one to draw: a numbered circle with a connector to the next
      # step (`:circle`, for vertical and rail), the bare dot of the quick flow
      # (`:dot`), or the quiet glyph of the progress shape (`:progress`).
      # Everything below it is the same markup, which is why one template
      # covers all four; so is the `sr-only` state name beside it, since no
      # marker says the state in anything but colour.
      #
      # `connector_state` is written by the parent once every step is declared
      # — it is the state of the step that FOLLOWS this one, or nil on the last
      # step and on every step of the horizontal shape.
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

        # Not `CONNECTOR_CLASSES` under another name. The dot is a marker, so
        # `:current` keeps the ring the circle gets; and with no number left to
        # read, `:skipped` goes hollow instead of one shade of grey away from
        # `:pending` — measured at 10px, the two greys were the same dot. A
        # hollow one says the route went around this step.
        DOT_CLASSES = {
          success: "bg-success",
          error: "bg-error",
          warning: "bg-warning",
          pending: "bg-base-300",
          skipped: "bg-base-100 ring-1 ring-base-300",
          current: "bg-primary ring-2 ring-primary/40"
        }.freeze

        # The progress shape's marker. The rail spends a colour per state on
        # both the circle and the line; here the line stays monochrome, so the
        # circle carries the whole verdict — filled for the three states that
        # settled, outlined for the three that did not.
        #
        # `:pending` and `:skipped` declare no background on purpose: the
        # connector runs centre-to-centre UNDER every marker, and the opaque
        # ground it needs is drawn once by `.workflow-step-marker::before`
        # (index.css) instead of six times here.
        PROGRESS_CIRCLE_CLASSES = {
          success: "bg-primary text-primary-content",
          error: "bg-error text-error-content",
          warning: "bg-warning text-warning-content",
          pending: "border border-base-300 text-base-content/30",
          skipped: "border border-dashed border-base-300 text-base-content/40",
          current: "border-2 border-primary bg-primary/10 text-primary"
        }.freeze

        # Monochrome, and that is the shape: the line says how far the flow
        # got, never what happened on the way. Reached is every state but
        # `:pending` — `:skipped` included, because a step the route went
        # around was still passed, and `:error` too, because a rejection is
        # somewhere the flow arrived. So the primary run ends at the first
        # `:pending` step, which is where a reader stops counting.
        PROGRESS_CONNECTOR_CLASSES = {
          success: "bg-primary",
          error: "bg-primary",
          warning: "bg-primary",
          pending: "bg-base-300",
          skipped: "bg-primary",
          current: "bg-primary"
        }.freeze

        # `:error` and `:warning` read at the weight of `:success`: all three
        # are steps the flow reached, and which one it was is the marker's job.
        # `:skipped` and `:pending` are the two the reader has no news about.
        PROGRESS_TITLE_CLASSES = {
          success: "text-base-content/80",
          error: "text-base-content/80",
          warning: "text-base-content/80",
          pending: "text-base-content/50",
          skipped: "text-base-content/50",
          current: "font-semibold text-primary"
        }.freeze

        # A settled verdict replaces the number with its glyph: once the flow
        # is past a step, where it sat in the order stops being the news.
        # `:skipped` needs no entry — it carries no number, so the dash every
        # numberless circle already falls back to is its glyph.
        PROGRESS_ICONS = {
          success: "check",
          error: "x",
          warning: "triangle-alert"
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
        # @param state_label [String, nil] Accessible name for this step's
        #   state. Defaults to the generic translation of `state`.
        # @param marker [Symbol] `:circle` (default), the quick flow's `:dot`,
        #   or the progress shape's `:progress`. Set by the parent from its
        #   own `orientation:`, which is validated there.
        # @param options [Hash] HTML attributes for the `<li>`
        def initialize(title:, state:, number: nil, assignee: nil, date: nil,
                       state_label: nil, marker: :circle, **options)
          @title = title
          @state = validated_state(state)
          @number = number
          @assignee = assignee
          @date = date
          @state_label = state_label
          @marker = marker
          @options = options
          @connector_state = nil
        end

        def skipped?
          state == SKIPPED
        end

        def dot?
          @marker == :dot
        end

        def progress?
          @marker == :progress
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
          table = progress? ? PROGRESS_CIRCLE_CLASSES : CIRCLE_CLASSES
          class_names("workflow-step-circle", table.fetch(state))
        end

        # The number is the circle's content wherever there is one to show; the
        # progress shape takes it back from the three states that have a glyph.
        def circle_number?
          progress_icon.nil? && number.present?
        end

        def circle_icon
          progress_icon || "minus"
        end

        def progress_icon
          PROGRESS_ICONS[state] if progress?
        end

        def dot_classes
          class_names("workflow-step-dot", DOT_CLASSES.fetch(state))
        end

        # Read into the `sr-only` span next to the marker, in all three
        # shapes: colour is the only thing any marker uses to say what
        # happened, and colour is nothing to a screen reader. The circle's
        # number does not cover it — a position is not a verdict.
        #
        # Overriding `bali_view.workflow_steps.states.*` changes them for every
        # flow in the app, so `state_label:` is the per-step hatch, shaped like
        # `Bali::BooleanIcon#label`: `nil` falls back to the translation,
        # anything else is literal, `""` included. `.presence ||` would hand the
        # generic string back to a caller who asked for silence.
        def state_label
          @state_label || I18n.t("bali_view.workflow_steps.states.#{state}")
        end

        def connector_classes
          table = progress? ? PROGRESS_CONNECTOR_CLASSES : CONNECTOR_CLASSES
          class_names("workflow-step-connector", table.fetch(connector_state))
        end

        def title_classes
          return class_names("workflow-step-title", PROGRESS_TITLE_CLASSES.fetch(state)) if progress?

          class_names(
            "workflow-step-title",
            "text-base-content/40" => MUTED_TITLE_STATES.include?(state)
          )
        end
      end
    end
  end
end
