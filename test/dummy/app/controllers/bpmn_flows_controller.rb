# frozen_string_literal: true

# The detail of Bali::BpmnEditor's «split view» preview: the flow behind a box
# of the process map, rendered into the SplitView's Turbo Frame when the box
# is clicked (bpmn_split_view_controller.js points the frame here). What a
# host's own detail action looks like: one record, its versions, a frame.
#
#   GET /bpmn_flows/:box?version=N&locale=es&filled=1&delay=800
#
# `delay` (milliseconds, at most MAX_DELAY) holds the response back, so the
# SplitView's loading state can be seen; dummy only.
class BpmnFlowsController < ApplicationController
  MAX_DELAY = 3000

  def show
    sleep(params[:delay].to_i.clamp(0, MAX_DELAY) / 1000.0)
    @locale = I18n.locale
    boxes = BpmnProcessMap.boxes(@locale)
    @box = boxes.find { |box| box[:id] == params[:box] } or raise ActionController::RoutingError, "no box #{params[:box]}"
    @versions = @box[:flow] ? BpmnProcessMap.flow_records(@locale).fetch(@box[:flow]) : []
    @version = @versions.find { |entry| entry[:number].to_s == params[:version].to_s } || @versions.first
    @filled = params[:filled] == "1"
    render layout: false
  end
end
