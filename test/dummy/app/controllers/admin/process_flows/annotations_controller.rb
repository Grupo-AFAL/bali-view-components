# frozen_string_literal: true

module Admin
  module ProcessFlows
    # Reference implementation of the notes endpoint of Bali::BpmnEditor
    # (`annotatable:` with `urls[:annotations]`): a read-only diagram whose
    # review notes are still written. Same protocol as the diagram's save
    # (DiagramsController), but only the notes travel and only they change:
    #
    #   PUT { annotations: [...], version: }
    #       → 200 the complete document (new version)
    #       → 409 when `version` is not the current one (the island re-GETs urls[:diagram])
    #       → 422 { errors: [...] } when a note is malformed
    class AnnotationsController < BaseController
      # Dummy-only, as in DiagramsController: Lookbook previews emit no CSRF token.
      skip_forgery_protection
      include DemoServer

      def update
        return head :conflict if demo_server == "conflict"

        annotations = Array(params.to_unsafe_h.fetch(:annotations, []))
        # The notes are checked inside the document they belong to: every one
        # needs an id, as Bali::BpmnEditor::Data asks of any document.
        Bali::BpmnEditor::Data.new(flow.document.merge("annotations" => annotations))
        return head :conflict unless flow.save_annotations(annotations, params[:version])

        render json: demo_diagram(flow)
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
