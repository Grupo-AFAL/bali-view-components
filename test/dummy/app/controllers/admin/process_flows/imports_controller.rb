# frozen_string_literal: true

module Admin
  module ProcessFlows
    # The "Import BPMN" extension point (urls[:import]): the editor opens `new`
    # in the layout's drawer with `editor_id`; the app takes the file, turns it
    # into the document contract and answers bali_bpmn_reload, after which the
    # editor GETs the diagram again.
    #
    # This dummy does not parse BPMN — that needs an XML mapping a real app
    # writes against its own data. Its `create` puts the flow back to its
    # sample and answers the reload, so the button, the drawer and the event
    # round trip can be tried as they are.
    class ImportsController < BaseController
      skip_forgery_protection

      def new
        render layout: false
      end

      def create
        flow.update!(document: BpmnSampleFlows.sample(sample_of(flow), locale: params[:locale] || :es)
                                              .except(:version, :status_label),
                     version: flow.version + 1, finalized_at: nil)
        render formats: :turbo_stream
      end

      private

      def flow
        @flow ||= ProcessFlow.find(params[:process_flow_id])
      end

      def sample_of(flow)
        flow.name[/\ASample (\w+)/, 1] || "invoice"
      end
    end
  end
end
