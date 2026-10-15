# frozen_string_literal: true

module Bali
  # Exposed to host views (see the engine initializer): how a host's drawer
  # form tells Bali::BpmnEditor it created something. Renders the
  # `bali_bpmn_event` Turbo Stream action the island installs
  # (app/components/bali/bpmn_editor/streamAction.js), which dispatches
  # `bali-bpmn:<event>` on the editor element.
  #
  #   # create.turbo_stream.erb, after saving the new procedure
  #   <%= bali_bpmn_reference_created(target: params[:editor_id],
  #         client_node_id: params[:client_node_id],
  #         reference: { id: procedure.id, label: procedure.name, url: procedure_path(procedure) }) %>
  module BpmnEditorHelper
    EVENTS = %w[reference-created lane-assignee-created reload].freeze

    # @param event [String] one of EVENTS
    # @param target [String] DOM id of the editor (its `id:`); without it the
    #   event goes to `document` and reaches every editor on the page.
    def bali_bpmn_event(event, target: nil, **detail)
      event = event.to_s
      raise ArgumentError, "unknown BPMN editor event #{event.inspect}; expected #{EVENTS.inspect}" if EVENTS.exclude?(event)

      # Written out rather than through turbo-rails' turbo_stream_action_tag:
      # this file is eager-loaded in every host and the gemspec does not
      # declare turbo-rails (test/bali/packaging/dependency_contract_test.rb).
      content_tag("turbo-stream", tag.template, action: "bali_bpmn_event", target: target.presence,
                                                 event: event, detail: detail.to_json)
    end

    def bali_bpmn_reference_created(client_node_id:, reference:, target: nil)
      bali_bpmn_event("reference-created", target: target, client_node_id: client_node_id.to_s,
                                           reference: normalize_reference(reference))
    end

    def bali_bpmn_lane_assignee_created(client_lane_id:, assignee:, target: nil)
      bali_bpmn_event("lane-assignee-created", target: target, client_lane_id: client_lane_id.to_s,
                                               assignee: normalize_reference(assignee))
    end

    def bali_bpmn_reload(target: nil)
      bali_bpmn_event("reload", target: target)
    end

    private

    def normalize_reference(reference)
      reference = reference.to_h.symbolize_keys
      raise ArgumentError, "a reference needs an id and a label" if reference[:id].blank? || reference[:label].blank?

      reference.slice(:id, :label, :url, :group, :description).merge(id: reference[:id].to_s).compact
    end
  end
end
