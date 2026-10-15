# frozen_string_literal: true

module Admin
  module ProcessFlows
    # Reference (executable) implementation of the Bali::BpmnEditor save
    # contract (#1489):
    #
    #   GET → the complete document
    #   PUT { diagram:, version: }
    #       → 200 the complete document (new version, server issues)
    #       → 409 when `version` is not the current one (the island re-GETs)
    #       → 422 { errors: [...] } when the document is malformed
    class DiagramsController < BaseController
      # Dummy-only: Lookbook previews emit no CSRF token. Hosts keep forgery
      # protection on — the island sends the token through @rails/request.js.
      skip_forgery_protection

      def show
        render json: flow.to_diagram
      end

      def update
        diagram = Bali::BpmnEditor::Data.new(params.require(:diagram).to_unsafe_h).to_h
        return head :conflict unless flow.save_draft(diagram, params[:version])

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
