# frozen_string_literal: true

# Manages comments within a BlockEditor thread.
module BlockEditorThreads
  class CommentsController < ApplicationController
    include BlockEditorAuthentication

    before_action :set_thread
    before_action :set_comment, only: %i[update destroy]

    def create
      comment = @thread.block_editor_comments.create!(
        user_id: current_user_id,
        body: comment_params[:body],
        metadata: comment_params[:metadata] || {}
      )
      render json: comment, status: :created
    end

    def update
      @comment.update!(
        body: comment_params[:body],
        metadata: comment_params.key?(:metadata) ? comment_params[:metadata] : @comment.metadata
      )
      render json: @comment
    end

    def destroy
      @comment.soft_delete!
      head :no_content
    end

    private

    def set_thread
      @thread = BlockEditorThread.find(params[:block_editor_thread_id])
    end

    def set_comment
      @comment = @thread.block_editor_comments.find(params[:id])
    end

    def comment_params
      params.permit(:body, metadata: {})
    end
  end
end
