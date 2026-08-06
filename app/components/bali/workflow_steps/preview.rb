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
