# frozen_string_literal: true

module Bali
  module BlockEditorThreads
    # #706 — comments inside a thread.
    #
    #   create           → anyone the authorize lambda lets in
    #   update / destroy → the comment's own author, and nobody else
    class CommentsController < BaseController
      before_action :set_thread
      before_action :set_comment, only: %i[update destroy]
      before_action :require_comment_author!, only: %i[update destroy]

      def create
        comment = @thread.comments.create!(
          user_id: current_comments_user_id,
          body: permit_json(params[:body]),
          metadata: permit_json(params[:metadata]) || {}
        )

        render json: comment, status: :created
      end

      def update
        attributes = { body: permit_json(params[:body]) }
        # Assigning metadata unconditionally would blank it on every body-only edit,
        # which is what the store sends when a comment is re-saved without one.
        attributes[:metadata] = permit_json(params[:metadata]) || {} if params.key?(:metadata)
        @comment.update!(attributes)

        render json: @comment
      end

      def destroy
        @comment.soft_delete!
        # A thread whose every comment is gone has nothing left to anchor or render,
        # and the editor's mark is removed client-side on the same action.
        @thread.destroy! if @thread.comments.active.none?

        head :no_content
      end

      private

      def set_comment
        @comment = @thread.comments.find(params[:id])
      end

      def require_comment_author!
        head :forbidden unless @comment.user_id == current_comments_user_id
      end
    end
  end
end
