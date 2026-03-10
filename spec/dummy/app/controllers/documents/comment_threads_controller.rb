# frozen_string_literal: true

# Document-scoped comment threads controller.
# Threads are scoped to a specific document, ensuring comments from different
# documents don't leak into each other.
module Documents
  class CommentThreadsController < ApplicationController
    include BlockEditorAuthentication

    before_action :set_document
    before_action :set_thread, only: %i[update destroy]

    def index
      render json: @document.block_editor_threads.with_comments.order(updated_at: :desc)
    end

    def create
      thread = @document.block_editor_threads.build(metadata: thread_params[:metadata] || {})

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

    def set_document
      @document = Document.find(params[:document_id])
    end

    def set_thread
      @thread = @document.block_editor_threads.find(params[:id])
    end

    def thread_params
      params.permit(:resolved, metadata: {})
    end
  end
end
