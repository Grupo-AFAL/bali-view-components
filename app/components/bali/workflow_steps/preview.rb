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
      # <%= render Bali::WorkflowSteps::Component.new(variant: :horizontal) do |c| %>
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
      # The dot carries its state name as an `aria-label`
      # (`bali_view.workflow_steps.states.*`, overridable like any Bali
      # string), because with no number left in the marker, colour is the only
      # thing saying what happened.
      #
      # `progress: false` drops the bar. Asking for one on the vertical variant
      # raises: that shape has no header to hang it on.
      def horizontal(progress: true)
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
