# frozen_string_literal: true

# Document-scoped comment management.
module Documents
  module CommentThreads
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
        document = Document.find(params[:document_id])
        @thread = document.block_editor_threads.find(params[:comment_thread_id])
      end

      def set_comment
        @comment = @thread.block_editor_comments.find(params[:id])
      end

      def comment_params
        result = { body: permit_json(params[:body]) }
        result[:metadata] = permit_json(params[:metadata]) || {} if params.key?(:metadata)
        result
      end
    end
  end
end
