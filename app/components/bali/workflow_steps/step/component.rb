# frozen_string_literal: true

module Bali
  module WorkflowSteps
    module Step
      # One step of a workflow: a marker, the title, and the optional assignee
      # / date / free comment block.
      #
      # The marker is the only thing the four titled shapes disagree on.
      # Everything below it is the same markup, which is why one template
      # covers all four; so is the `sr-only` state name beside it, since no
      # marker says the state in anything but colour. The segments shape is
      # the fifth and paints no title, so its step is a branch of its own.
      #
      # `marker` and `connector_state` are written by the parent, not passed to
      # `new`: `dot:` is the boolean v3.4.0 published, which leaves the other
      # markers no keyword to arrive through, and `connector_state` is the
      # FOLLOWING step's state, unknowable until every step is declared — nil
      # on the last step and on every step of the horizontal and segments
      # shapes.
      class Component < ApplicationViewComponent
        SKIPPED = :skipped

        # Literal class tables, like `Stepper::Step::COLORS`: Tailwind's source
        # scanner only sees classes written out in full in this file.
        #
        # The two greys draw their number or dash at `/70`: on the pending
        # circle's `base-300` it measures 4.98:1 on `afal`, the lowest of the
        # five themes, where `/60` was 3.75:1.
        CIRCLE_CLASSES = {
          success: "bg-success text-success-content",
          error: "bg-error text-error-content",
          warning: "bg-warning text-warning-content",
          pending: "bg-base-300 text-base-content/70",
          skipped: "bg-base-200 text-base-content/70",
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

        # `:pending` and `:skipped` declare no background on purpose: the
        # connector runs centre-to-centre UNDER every marker, and the opaque
        # ground it needs is drawn once by `.workflow-step-marker::before`
        # (index.css) instead of six times here.
        #
        # Their greys are measured over that disc, not picked, on the five
        # themes, and `afal` is the floor of both: `base-content` clears AA's
        # 4.5:1 for the glyph at `/70` (5.54:1; `/60` is 4.04:1) and 3:1 for
        # the outline at `/50` (3.05:1). `base-300`, which the rail uses for
        # both, tops out at 1.16:1.
        PROGRESS_CIRCLE_CLASSES = {
          success: "bg-primary text-primary-content",
          error: "bg-error text-error-content",
          warning: "bg-warning text-warning-content",
          pending: "border border-base-content/50 text-base-content/70",
          skipped: "border border-dashed border-base-content/50 text-base-content/70",
          current: "border-2 border-primary bg-primary/10 text-primary"
        }.freeze

        # Reached is every state but `:pending` — `:skipped` included, because
        # a step the route went around was still passed, and `:error` too,
        # because a rejection is somewhere the flow arrived. So the primary run
        # ends at the first `:pending` step, and nowhere else: a chain that is
        # all `:skipped` draws a full primary line, and a reached step after
        # `:current` carries the colour past it.
        #
        # The grey half takes the outline's `/50` for the same 3:1: the whole
        # answer of this shape is the line, and `bg-base-300` measured 1.16:1.
        PROGRESS_CONNECTOR_CLASSES = {
          success: "bg-primary",
          error: "bg-primary",
          warning: "bg-primary",
          pending: "bg-base-content/50",
          skipped: "bg-primary",
          current: "bg-primary"
        }.freeze

        # The muted `/70` holds AA, it is not a shade to tune: these labels are
        # 12px, so AA wants 4.5:1, and `/60` measured 4.04:1 on `afal`.
        PROGRESS_TITLE_CLASSES = {
          success: "text-base-content/80",
          error: "text-base-content/80",
          warning: "text-base-content/80",
          pending: "text-base-content/70",
          skipped: "text-base-content/70",
          current: "font-semibold text-primary"
        }.freeze

        # `:skipped` needs no entry — it carries no number, so the dash every
        # numberless circle already falls back to is its glyph.
        PROGRESS_ICONS = {
          success: "check",
          error: "x",
          warning: "triangle-alert"
        }.freeze

        # Each state is a different SHAPE, not only a different colour (WCAG
        # 1.4.1): solid, hatched, half-filled, a thin line for the step the
        # route went around, solid and outlined for the current one, hollow for
        # what has not happened. Measured through a deuteranopia filter, success
        # and error are the same brown and only the hatching tells them apart.
        #
        # The three state colours are 60% the state's own colour and 40%
        # `base-content`, because the plain fills are below the 3:1 a shape
        # carrying meaning needs (1.4.11) in every light theme: `success`
        # 1.96:1, `warning` 1.76:1 and `error` 2.86:1 on light's `base-100`.
        # At 60% the worst of the fifteen theme × state pairs is `warning` in
        # `afal`, 3.80:1 on `base-100` and 3.45:1 on the `base-200` of a zebra
        # row; 70% left it at 2.78:1. `primary` and the `base-content/60` grey
        # pass as they are.
        SEGMENT_CLASSES = {
          success: "bg-current " \
                   "text-[color-mix(in_oklab,var(--color-success)_60%,var(--color-base-content))]",
          error: "bg-[repeating-linear-gradient(-45deg,currentColor_0_1.5px,transparent_1.5px_3.5px)] " \
                 "text-[color-mix(in_oklab,var(--color-error)_60%,var(--color-base-content))]",
          warning: "bg-[linear-gradient(to_right,currentColor_50%,transparent_50%)] " \
                   "text-[color-mix(in_oklab,var(--color-warning)_60%,var(--color-base-content))]",
          pending: "text-base-content/60",
          skipped: "h-0.5 border-0 bg-current text-base-content/60",
          current: "bg-current text-primary outline-2 outline-offset-1 outline-current"
        }.freeze

        # Forced colours repaint `background-color` as Canvas and drop every
        # `background-image` that is not a url: measured, success, error,
        # warning and pending came out as the same hollow pill and `:skipped`
        # vanished. Opting out paints all six shapes in CanvasText instead.
        # Here and not in index.css: the colour is set by a `text-*` utility,
        # which no rule in @layer components can beat.
        SEGMENT_FORCED_COLORS_CLASSES =
          "forced-colors:forced-color-adjust-none forced-colors:text-[color:CanvasText]"

        STATES = CIRCLE_CLASSES.keys.freeze

        # Steps that have not happened read muted, like the rest of their row —
        # at the `/70` of the assignee and the comment, because `/40` measured
        # 2.36:1 on `afal` against AA's 4.5:1.
        MUTED_TITLE_STATES = %i[pending skipped].freeze

        attr_reader :title, :state, :number, :assignee, :date
        attr_accessor :connector_state

        # Writer public, reader private, deliberately not an `attr_accessor`:
        # the parent is the only thing that may set this.
        attr_writer :marker

        # @param title [String] The step's name
        # @param state [Symbol] One of STATES
        # @param number [Integer, String, nil] Circle content; nil renders a dash
        # @param assignee [String, nil] Who the step belongs to
        # @param date [String, nil] Preformatted date/time text
        # @param state_label [String, nil] Accessible name for this step's
        #   state. Defaults to the generic translation of `state`.
        # @param dot [Boolean] Draw the quick flow's dot instead of the
        #   numbered circle. Set by the parent from its `orientation:`.
        # @param options [Hash] HTML attributes for the `<li>`
        def initialize(title:, state:, number: nil, assignee: nil, date: nil,
                       state_label: nil, dot: false, **options)
          @title = title
          @state = validated_state(state)
          @number = number
          @assignee = assignee
          @date = date
          @state_label = state_label
          @dot = dot
          @options = options
          @marker = nil
          @connector_state = nil
        end

        def skipped?
          state == SKIPPED
        end

        def dot?
          marker == :dot
        end

        def progress?
          marker == :progress
        end

        def segment?
          marker == :segment
        end

        private

        attr_reader :options

        # An explicit `dot: true` outranks the parent, which is what v3.4.0
        # already did when the keyword and the parent's own `dot: horizontal?`
        # met in the same call.
        def marker
          return :dot if @dot

          @marker || :circle
        end

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

        def segment_classes
          class_names("workflow-step-segment", SEGMENT_CLASSES.fetch(state),
                      SEGMENT_FORCED_COLORS_CLASSES)
        end

        # The segment's whole text, for the `title` a pointer hovers and the
        # `sr-only` copy a screen reader reads; `state_label: ""` leaves the
        # title alone, without a dangling separator.
        def segment_label
          [ title, state_label ].compact_blank.join(": ")
        end

        def connector_classes
          table = progress? ? PROGRESS_CONNECTOR_CLASSES : CONNECTOR_CLASSES
          class_names("workflow-step-connector", table.fetch(connector_state))
        end

        def title_classes
          return class_names("workflow-step-title", PROGRESS_TITLE_CLASSES.fetch(state)) if progress?

          class_names(
            "workflow-step-title",
            "text-base-content/70" => MUTED_TITLE_STATES.include?(state)
          )
        end
      end
    end
  end
end
