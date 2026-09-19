# frozen_string_literal: true

module Bali
  module WorkflowSteps
    class Preview < ApplicationViewComponentPreview
      # WorkflowSteps
      # -------------
      # Steps of a flow with a verdict per step. `Stepper` is a wizard by
      # index (one `current:`, look derived from position); `WorkflowSteps`
      # gives every step its own semantic state — the shape of an approval
      # chain, a signature round or an onboarding checklist.
      #
      # The connector under each circle takes the state of the **next** step,
      # so the line arrives coloured at the step that owns the verdict. The
      # component computes that; callers only declare states.
      #
      # ```erb
      # <%= render Bali::WorkflowSteps::Component.new do |c| %>
      #   <% c.with_step(title: 'Submitted', state: :success, date: 'Jul 1') %>
      #   <% c.with_step(title: 'Legal review', state: :error) do %>
      #     Rejected: missing appendix B.
      #   <% end %>
      #   <% c.with_step(title: 'Director signature', state: :pending) %>
      # <% end %>
      # ```
      #
      # States: `:success`, `:error`, `:warning`, `:current` (ring emphasis),
      # `:pending`, and `:skipped` — muted, no number, and it consumes no
      # position in the auto-numbering (an explicit `number:` always wins).
      #
      # The circle says the state in colour and the number says a position, so
      # each step also renders an `sr-only` name for it
      # (`bali_view.workflow_steps.states.*`, overridable like any Bali string
      # when the host's domain has better words: "Signed", "Returned").
      # `state_label:` on a single step overrides that one name without
      # touching the global strings — for the screen where `:skipped` means
      # "Not taken" and everywhere else it still means "Skipped".
      #
      # A step's block is its comment, and a block that renders blank draws no
      # comment container at all — a host's `if` *inside* the block leaves the
      # step exactly as one declared with no block at all.
      def default
        render_with_template
      end

      # @param progress toggle
      # Horizontal — the quick flow
      # ---------------------------
      # The same steps as a row of cards with an N/M bar on top, for the
      # summary card or the table cell where the whole chain has to fit in a
      # glance. Same `with_step` API; the marker becomes a dot, and there are
      # no connectors — the bar already says how far the flow got.
      #
      # ```erb
      # <%= render Bali::WorkflowSteps::Component.new(orientation: :horizontal) do |c| %>
      #   <% c.with_step(title: 'Submitted', state: :success, date: 'Jul 1') %>
      #   <% c.with_step(title: 'Legal review', state: :current) %>
      #   <% c.with_step(title: 'Director signature', state: :pending) %>
      # <% end %>
      # ```
      #
      # **N counts the steps with a verdict** — `:success`, `:error`,
      # `:warning` and `:skipped`. A skipped step is settled, and it is still
      # one of the dots on screen, so counting it keeps N/M matching what the
      # reader can count. `:pending` and `:current` are the two that have not
      # happened yet. **The bar takes the flow's verdict**: red if any step was
      # rejected, amber if any came back with observations, neutral otherwise.
      #
      # The dot is decorative: the state name is announced by the same
      # `sr-only` span the vertical variant renders next to its circle
      # (`bali_view.workflow_steps.states.*`, overridable like any Bali
      # string).
      #
      # `progress: false` drops the bar. Asking for one on the vertical variant
      # raises: that shape has no header to hang it on.
      #
      # **Cards or rail?** Cards when the chain is short and each step carries
      # meta worth reading side by side. Rail when the chain is long and what
      # matters is the order and how far it got — cards wrap by design, and a
      # nine-step funnel in three rows is no longer a funnel.
      def horizontal(progress: true)
        render_with_template(locals: { progress: progress })
      end

      # @param progress toggle
      # Rail — the funnel in one row
      # ----------------------------
      # `orientation: :rail` puts every step on one line: numbered circle,
      # coloured connector to the next one, label centred underneath. The shape
      # for a long flow at the top of a page, where the reader needs the order
      # and the reach of the flow before any detail.
      #
      # ```erb
      # <%= render Bali::WorkflowSteps::Component.new(orientation: :rail) do |c| %>
      #   <% c.with_step(title: 'Capture', state: :success) %>
      #   <% c.with_step(title: 'Evaluation', state: :skipped, state_label: 'Not taken') %>
      #   <% c.with_step(title: 'Project', state: :pending) %>
      # <% end %>
      # ```
      #
      # It is the vertical shape's marker laid sideways: **numbered circles**
      # (auto-numbering and `:skipped` skipping positions work exactly as
      # there) and **connectors that take the state of the next step**, so the
      # line arrives coloured at the step that owns the verdict.
      #
      # **The N/M bar is off by default here**, unlike the horizontal shape:
      # the connectors already draw how far the flow got. `progress: true`
      # turns it on.
      #
      # **It does not wrap.** Equal columns down to a `6rem` floor, and below
      # that the row scrolls inside the component — the page never gains a
      # horizontal scrollbar. Wrapping is what the horizontal cards do.
      #
      # That scroll is reachable with the keyboard: the row is a tab stop
      # (`tabindex="0"` plus an `aria-label` from
      # `bali_view.workflow_steps.rail_label`), because a scroll container with
      # nothing focusable inside it hides its overflow from anyone without a
      # pointer. Tab to the last group below and use the arrow keys.
      #
      # `assignee:`, `date:` and the block still render, centred under the
      # label. Nothing is hidden; they set the row height, so a rail that has
      # to stay one line tall is one whose caller leaves them out.
      def rail(progress: false)
        render_with_template(locals: { progress: progress })
      end

      # Decision pattern (approve / reject)
      # -----------------------------------
      # The form that goes next to the flow is **the host's**, not a Bali
      # component: it owns the route, the params and the policy. What is worth
      # copying is its shape, which is the same in every approval screen:
      #
      # ```erb
      # <%= form_with url: decision_path(request), method: :post, builder: Bali::FormBuilder do |f| %>
      #   <%= f.text_area_group :notes, label: 'Notes', rows: 3, required: true %>
      #   <%= f.submit_field 'Approve', variant: :success,
      #         name: 'decision', value: 'approve', formnovalidate: true %>
      #   <%= f.submit_field 'Reject', variant: :error, style: :outline,
      #         name: 'decision', value: 'reject',
      #         data: { turbo_confirm: 'Reject this request?' } %>
      # <% end %>
      # ```
      #
      # Three things carry it:
      #
      # - **One form, two submits told apart by `name:`/`value:`.** The
      #   controller reads `params[:decision]`, and the notes are typed once
      #   whichever way it goes.
      # - **`required: true` on the notes + `formnovalidate` on Approve.** The
      #   browser demands a reason to reject and asks nothing to approve — no
      #   JavaScript, no second field, no server-side branch to keep in sync
      #   with the markup.
      # - **`turbo_confirm` on the destructive half only.** A rejection usually
      #   ends the route; an approval moves it along and is undone by the next
      #   step.
      #
      # Nothing here is a component and nothing here is planned to become one:
      # `formnovalidate` is a property of *this* form, and packaging it would
      # be the first step towards the workflow engine this component
      # deliberately is not.
      def decision_pattern
        render_with_template
      end

      # Provisional route
      # -----------------
      # Before a request is typed, the whole step definition is shown and an
      # informative note explains that the route may shrink; the note belongs
      # to the host (here a `Bali::Notification`), not to the component. Once
      # typed, the steps the route omits become `:skipped`: muted, no number,
      # and the numbering counts the real route only.
      def provisional_route
        render_with_template
      end
    end
  end
end
