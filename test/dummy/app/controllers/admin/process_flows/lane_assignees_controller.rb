# frozen_string_literal: true

module Admin
  module ProcessFlows
    # The lane-responsible extension points of Bali::BpmnEditor: a grouped
    # search (`group` narrows it) and a drawer that creates a new one.
    class LaneAssigneesController < BaseController
      skip_forgery_protection

      def index
        render json: ProcessFlowReferences.search(ProcessFlowReferences.assignees(params[:locale] || :es), params[:q], params[:group])
      end

      def new
        render layout: false
      end

      def create
        label = params.require(:assignee).require(:label)
        @assignee = ProcessFlowReferences.create_assignee(label, params.dig(:assignee, :group).presence || "Rol")
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
