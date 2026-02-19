# frozen_string_literal: true

# Manages BlockEditor comment threads.
# Part of the BlockEditor inline comments REST API — see RESTThreadStore.js for the JS contract.
class BlockEditorThreadsController < ApplicationController
  include BlockEditorAuthentication

  before_action :set_thread, only: %i[update destroy]

  def index
    render json: BlockEditorThread.with_comments.order(updated_at: :desc)
  end

  def create
    thread = BlockEditorThread.new(metadata: thread_params[:metadata] || {})

    if params[:initial_comment].present?
      ic = params[:initial_comment]
      thread.block_editor_comments.build(
        user_id: current_user_id,
        body: permit_json(ic[:body]),
        metadata: permit_json(ic[:metadata]) || {}
      )
    end

    thread.save!
    render json: thread, status: :created
  end

  def update
    if thread_params.key?(:resolved)
      thread_params[:resolved] ? @thread.resolve!(current_user_id) : @thread.unresolve!
    end
    render json: @thread
  end

  def destroy
    @thread.destroy!
    head :no_content
  end

  private

  def set_thread
    @thread = BlockEditorThread.find(params[:id])
  end

  def thread_params
    params.permit(:resolved, metadata: {})
  end
end
