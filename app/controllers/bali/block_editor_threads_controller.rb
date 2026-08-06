# frozen_string_literal: true

module Bali
  # #706 — threads of the BlockEditor's inline comments. Four of the nine endpoints
  # `RESTThreadStore` calls; the other five live in the two nested controllers.
  #
  # Permissions mirror BlockNote's own `DefaultThreadStoreAuth`, because that is what
  # the UI already promises the user — and the client-side gate is decoration, this is
  # the only real one:
  #
  #   index / create / update (resolve, unresolve) → anyone the authorize lambda lets in
  #   destroy                                      → the author of the FIRST comment
  class BlockEditorThreadsController < BlockEditorThreads::BaseController
    before_action :set_thread, only: %i[update destroy]

    def index
      render json: threads.with_comments.order(updated_at: :desc)
    end

    def create
      initial_comment = params[:initial_comment]
      # A thread with no comments is undeletable (nobody is its first author) and
      # invisible in the editor. The store always sends one, so refusing is free.
      return head :unprocessable_content if initial_comment.blank?

      thread = BlockEditorThread.new(commentable: @commentable, metadata: permit_json(params[:metadata]) || {})
      thread.comments.build(
        user_id: current_comments_user_id,
        body: permit_json(initial_comment[:body]),
        metadata: permit_json(initial_comment[:metadata]) || {}
      )
      thread.save!

      render json: thread, status: :created
    end

    def update
      if params.key?(:resolved)
        resolved? ? @thread.resolve!(current_comments_user_id) : @thread.unresolve!
      end

      render json: @thread
    end

    def destroy
      return head :forbidden unless @thread.author_id == current_comments_user_id

      @thread.destroy!
      head :no_content
    end

    private

    def thread_id_param
      :id
    end

    # The store sends a JSON boolean, but a form-encoded "false" is a truthy String.
    def resolved?
      ActiveModel::Type::Boolean.new.cast(params[:resolved])
    end
  end
end
