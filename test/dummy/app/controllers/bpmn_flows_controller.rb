# frozen_string_literal: true

# The detail of Bali::BpmnEditor's «split view» preview: the flow behind a box
# of the process map, rendered into the SplitView's Turbo Frame when the box
# is clicked (bpmn_split_view_controller.js points the frame here). What a
# host's own detail action looks like: one record, its versions, a frame.
#
#   GET /bpmn_flows/:box?version=N&locale=es&filled=1&delay=800&compare=true
#
# The flow compares against its previous version and the other flows, from
# its own «Compare» menu; `compare` (true, side_by_side or overlay) opens it
# comparing against the first of them.
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
    records = BpmnProcessMap.flow_records(@locale)
    @versions = @box[:flow] ? records.fetch(@box[:flow]) : []
    @version = @versions.find { |entry| entry[:number].to_s == params[:version].to_s } || @versions.first
    @filled = params[:filled] == "1"
    @comparisons = comparisons(boxes, records) if @version
    @compare_open = params[:compare].presence && (params[:compare] == "true" || params[:compare].to_sym)
    render layout: false
  end

  private

  def comparisons(boxes, records)
    en = @locale.to_s == "en"
    older = @versions.select { |entry| entry[:number] < @version[:number] }.map do |entry|
      { document: entry[:flow].to_diagram(locale: @locale), label: en ? "Version #{entry[:number]}" : "Versión #{entry[:number]}" }
    end
    others = boxes.select { |box| box[:flow] && box[:flow] != @box[:flow] }.uniq { |box| box[:flow] }.map do |box|
      { document: records.fetch(box[:flow]).first[:flow].to_diagram(locale: @locale), label: box[:name] }
    end
    older + others
  end
end
