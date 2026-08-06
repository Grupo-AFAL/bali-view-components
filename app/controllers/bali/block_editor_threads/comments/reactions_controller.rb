# frozen_string_literal: true

module Bali
  module BlockEditorThreads
    module Comments
      # #706 — emoji reactions on a comment. No author matrix to write here: a
      # reaction is always the current user's, on both ends. `create` stamps
      # `user_id` from the lambda and `destroy` looks up by it, so there is no
      # request shape that touches somebody else's reaction.
      #
      # `DELETE` carries the emoji in the body (`RESTThreadStore._deleteWithBody`),
      # which Rails parses like any other JSON payload.
      class ReactionsController < BaseController
        before_action :set_comment

        def create
          reaction = @comment.reactions.create!(user_id: current_comments_user_id, emoji: emoji)

          render json: { emoji: reaction.emoji, user_id: reaction.user_id }, status: :created
        end

        def destroy
          @comment.reactions.find_by!(user_id: current_comments_user_id, emoji: emoji).destroy!

          head :no_content
        end

        private

        def set_comment
          set_thread
          @comment = @thread.comments.find(params[:comment_id])
        end

        def emoji
          params.require(:emoji)
        end
      end
    end
  end
end
