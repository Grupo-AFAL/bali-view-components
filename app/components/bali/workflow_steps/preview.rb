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
