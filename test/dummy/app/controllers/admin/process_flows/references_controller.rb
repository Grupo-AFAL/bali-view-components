# frozen_string_literal: true

module Admin
  module ProcessFlows
    # The sub-process extension points of Bali::BpmnEditor (#1489):
    #
    #   GET  index?q=  → [{ id, label, description, url, group }] for the search box
    #   GET  new?client_node_id=&editor_id= → the drawer form
    #   POST create    → a turbo stream that links the new entity to the node
    class ReferencesController < BaseController
      skip_forgery_protection

      def index
        render json: ProcessFlowReferences.search(ProcessFlowReferences.references, params[:q], params[:group])
                                          .map { |item| item.merge(url: admin_process_flow_path(flow)) }
      end

      def new
        render layout: false
      end

      def create
        label = params.require(:reference).require(:label)
        item = ProcessFlowReferences.create_reference(label, params.dig(:reference, :group).presence || "Compras")
        @reference = item.merge(url: admin_process_flow_path(flow))
        render formats: :turbo_stream
      rescue ActionController::ParameterMissing
        render :new, layout: false, status: :unprocessable_content
      end

      private

      def flow
        @flow ||= ProcessFlow.find(params[:process_flow_id])
      end
    end
  end
end
