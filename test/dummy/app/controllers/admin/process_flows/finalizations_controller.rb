# frozen_string_literal: true

module Admin
  module ProcessFlows
    # "Finalize flow": saves the posted document, and finalizes it only when
    # the server's own rules raise no error — otherwise 422 with `issues`, which
    # the island opens in its pending panel, and the new `version`: the draft
    # was saved, and the island's next save has to carry it.
    class FinalizationsController < BaseController
      skip_forgery_protection

      def create
        diagram = Bali::BpmnEditor::Data.new(params.require(:diagram).to_unsafe_h).to_h
        return head :conflict unless flow.save_draft(diagram, params[:version])

        errors = flow.server_issues.select { |issue| issue[:severity] == "error" }
        if errors.any?
          return render json: { errors: errors.pluck(:message), issues: flow.server_issues, version: flow.version },
                        status: :unprocessable_entity
        end

        flow.update!(finalized_at: Time.current)
        render json: flow.to_diagram
      rescue Bali::BpmnEditor::Data::InvalidError => e
        render json: { errors: [ e.message ] }, status: :unprocessable_entity
      end

      private

      def flow
        @flow ||= ProcessFlow.find(params[:process_flow_id])
      end
    end
  end
end
