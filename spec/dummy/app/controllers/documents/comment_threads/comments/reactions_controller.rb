# frozen_string_literal: true

# Document-scoped reaction management.
module Documents
  module CommentThreads
    module Comments
      class ReactionsController < ApplicationController
        include BlockEditorAuthentication

        before_action :set_comment

        def create
          reaction = @comment.block_editor_reactions.create!(
            user_id: current_user_id,
            emoji: reaction_params[:emoji]
          )
          render json: { emoji: reaction.emoji, user_id: reaction.user_id }, status: :created
        end

        def destroy
          @comment.block_editor_reactions.find_by!(
            user_id: current_user_id,
            emoji: reaction_params[:emoji]
          ).destroy!
          head :no_content
        end

        private

        def set_comment
          document = Document.find(params[:document_id])
          thread = document.block_editor_threads.find(params[:comment_thread_id])
          @comment = thread.block_editor_comments.find(params[:comment_id])
        end

        def reaction_params
          params.permit(:emoji)
        end
      end
    end
  end
end
