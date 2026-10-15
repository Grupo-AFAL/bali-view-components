# frozen_string_literal: true

module Admin
  # The BPMN editor in a real layout rather than a preview: the island's
  # asset paths go up through `content_for :head`.
  class ProcessFlowsController < BaseController
    def show
      @flow = ProcessFlow.find(params[:id])
    end
  end
end
