# frozen_string_literal: true

module Admin
  module ProcessFlows
    # The Lookbook "Host integration" preview's buttons: what an app answers
    # after its own work, through Bali::BpmnEditorHelper, to the editor whose
    # DOM id it names.
    #
    #   POST event=reload            → bali_bpmn_reload
    #   POST event=reference_created → bali_bpmn_reference_created for a node
    class HostEventsController < BaseController
      skip_forgery_protection

      def create
        editor = params.require(:editor_id)
        stream = case params.require(:event)
        when "reload" then helpers.bali_bpmn_reload(target: editor)
        when "reference_created"
                   reference = ProcessFlowReferences.references.first
                   helpers.bali_bpmn_reference_created(target: editor, client_node_id: params.require(:client_node_id),
                                                       reference: reference.merge(url: admin_process_flow_path(flow)))
        else return head :unprocessable_content
        end
        render turbo_stream: stream
      end

      private

      def flow
        @flow ||= ProcessFlow.find(params[:process_flow_id])
      end
    end
  end
end
