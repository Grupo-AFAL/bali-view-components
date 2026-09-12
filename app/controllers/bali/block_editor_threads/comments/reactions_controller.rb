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
        # The unique index bounds re-tapping the SAME emoji; this bounds how many
        # DISTINCT emojis one user piles on one comment. Far above real use, and it
        # turns 50 requests → 50 rows → megabytes of index payload into a hard stop.
        MAX_REACTIONS_PER_USER = 20

        before_action :set_comment

        def create
          if @comment.reactions.where(user_id: current_comments_user_id).count >= MAX_REACTIONS_PER_USER
            return head :too_many_requests
          end

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
          # `.active`: a tombstone takes no new reactions — the frozen JSON contract
          # renders deleted comments bodyless and reaction-less.
          @comment = @thread.comments.active.find(params[:comment_id])
        end

        def emoji
          params.require(:emoji)
        end
      end
    end
  end
end
