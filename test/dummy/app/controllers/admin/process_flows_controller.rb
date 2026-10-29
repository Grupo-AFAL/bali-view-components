# frozen_string_literal: true

module Admin
  # The BPMN editor in a real layout rather than a preview: the island's
  # asset paths go up through `content_for :head`.
  class ProcessFlowsController < BaseController
    def show
      @flow = ProcessFlow.find(params[:id])
    end

    # The same editor with `full_page:`, inside this layout's side menu and topbar.
    def edit
      @flow = ProcessFlow.find(params[:id])
    end
  end
end
