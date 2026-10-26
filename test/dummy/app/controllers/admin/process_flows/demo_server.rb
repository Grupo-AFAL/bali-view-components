# frozen_string_literal: true

module Admin
  module ProcessFlows
    # DEMO ONLY — the Lookbook playground's `server` parameter. The preview adds
    # `?server=` to the editor's URLs and these endpoints answer the way a real
    # host would in that situation, so every branch of the save contract can be
    # tried by hand. A host has nothing like this.
    #
    #   conflict        PUT → 409, as if someone else had saved first
    #   error           PUT → 422 { errors: [...] }
    #   reject_save     PUT → 422 { errors, issues }: refused, naming the elements
    #   slow            every answer ~2 s late
    #   issues          the document comes back with pending issues of the server
    #   reject_finalize POST finalization → 422 { errors, issues, version }
    module DemoServer
      MODES = %w[normal conflict error reject_save slow issues reject_finalize].freeze

      extend ActiveSupport::Concern

      included do
        before_action { sleep 2 if demo_server == "slow" }
      end

      private

      def demo_server
        MODES.include?(params[:server]) ? params[:server] : "normal"
      end

      def demo_english?
        params[:locale].to_s == "en"
      end

      def demo_diagram(flow)
        diagram = flow.to_diagram(locale: params[:locale] || :es)
        return diagram unless demo_server == "issues"

        diagram.merge(issues: diagram[:issues] + demo_issues(flow))
      end

      # What a host's own rules might say: one warning on the flow, one error
      # on its first activity.
      def demo_issues(flow)
        first = Array(flow.document["nodes"]).find { |n| n["type"].to_s.end_with?("task") }
        [
          { rule: "APP-DEMO-1", element_id: nil, severity: "warning",
            message: demo_english? ? "The cost center is missing (server check)." : "Falta el centro de costos (validación del servidor)." },
          { rule: "APP-DEMO-2", element_id: first && first["id"], severity: "error",
            message: demo_english? ? "This activity has no owner in the app (server check)." : "Esta actividad no tiene responsable en la app (validación del servidor)." }
        ]
      end
    end
  end
end
