# frozen_string_literal: true

# REST API for BlockEditor comment threads.
# Implements the contract expected by RESTThreadStore.js.
class BlockEditorCommentsController < ApplicationController
  before_action :set_thread, only: %i[update destroy create_comment update_comment destroy_comment
                                      create_reaction destroy_reaction]
  before_action :set_comment, only: %i[update_comment destroy_comment create_reaction destroy_reaction]

  # GET /block_editor_comments
  def index
    threads = BlockEditorThread.with_comments.order(updated_at: :desc)
    render json: threads
  end

  # POST /block_editor_comments
  def create
    thread = BlockEditorThread.new(metadata: thread_params[:metadata] || {})

    if thread_params[:initial_comment].present?
      ic = thread_params[:initial_comment]
      thread.block_editor_comments.build(
        user_id: current_user_id,
        body: ic[:body],
        metadata: ic[:metadata] || {}
      )
    end

    thread.save!
    render json: thread, status: :created
  end

  # PATCH /block_editor_comments/:id
  def update
    if params.key?(:resolved)
      @thread.resolved = params[:resolved]
      @thread.resolved_by = params[:resolved] ? current_user_id : nil
      @thread.resolved_updated_at = Time.current
    end

    @thread.save!
    render json: @thread
  end

  # DELETE /block_editor_comments/:id
  def destroy
    @thread.destroy!
    head :no_content
  end

  # POST /block_editor_comments/:id/comments
  def create_comment
    comment = @thread.block_editor_comments.create!(
      user_id: current_user_id,
      body: comment_params[:body],
      metadata: comment_params[:metadata] || {}
    )
    render json: comment, status: :created
  end

  # PATCH /block_editor_comments/:id/comments/:comment_id
  def update_comment
    @comment.update!(
      body: comment_params[:body],
      metadata: comment_params.key?(:metadata) ? comment_params[:metadata] : @comment.metadata
    )
    render json: @comment
  end

  # DELETE /block_editor_comments/:id/comments/:comment_id
  def destroy_comment
    @comment.soft_delete!
    head :no_content
  end

  # POST /block_editor_comments/:id/comments/:comment_id/reactions
  def create_reaction
    reaction = @comment.block_editor_reactions.create!(
      user_id: current_user_id,
      emoji: reaction_params[:emoji]
    )
    render json: { emoji: reaction.emoji, user_id: reaction.user_id }, status: :created
  end

  # DELETE /block_editor_comments/:id/comments/:comment_id/reactions
  def destroy_reaction
    reaction = @comment.block_editor_reactions.find_by!(
      user_id: current_user_id,
      emoji: reaction_params[:emoji]
    )
    reaction.destroy!
    head :no_content
  end

  private

  def set_thread
    @thread = BlockEditorThread.find(params[:id])
  end

  def set_comment
    @comment = @thread.block_editor_comments.find(params[:comment_id])
  end

  # In the dummy app, we accept user_id from a header or default to "1"
  def current_user_id
    request.headers['X-User-Id'] || '1'
  end

  def thread_params
    params.permit(:resolved, metadata: {}, initial_comment: [:body, metadata: {}])
  end

  def comment_params
    params.permit(:body, metadata: {})
  end

  def reaction_params
    params.permit(:emoji)
  end
end
