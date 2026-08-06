# frozen_string_literal: true

module Bali
  module BlockEditorThreads
    # #706 — everything the three comment endpoints share: who the user is, what the
    # threads hang off, and whether this request is allowed near either.
    #
    # This is the engine's first WRITE surface reachable without a host controller in
    # front of it, so the defaults are deny-by-default in both directions:
    #
    # - `Bali.block_editor_commentables` starts empty, so an app that mounts the
    #   engine without configuring it answers 404 to every request here.
    # - `commentable_type`/`commentable_id` are REQUIRED on every action, including
    #   the ones that already carry a thread id. `RESTThreadStore` preserves the base
    #   URL's query string on all nine endpoints, so this costs the client nothing —
    #   and it is what stops `GET /` from being "every thread in the database", the
    #   bug this engine was written to leave behind.
    # - the type is resolved through the whitelist, never `constantize`.
    # - identity comes from `Bali.block_editor_comments_user`, NEVER from the
    #   `X-User-Id` header the store sends. That header is a hint for demos; trusting
    #   it would let any request author a comment as anyone.
    class BaseController < Bali::ApplicationController
      abstract!

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
      rescue_from ActiveRecord::RecordNotUnique, with: :render_conflict

      before_action :set_commentable
      before_action :authorize_comments!

      private

      def current_comments_user_id
        return @current_comments_user_id if defined?(@current_comments_user_id)

        @current_comments_user_id = Bali.block_editor_comments_user.call(self).presence&.to_s
      end

      def set_commentable
        @commentable = resolve_commentable
        head :not_found if @commentable.nil?
      end

      # A missing type, a type nobody whitelisted and an id that resolves to nothing
      # are all the same answer: 404. Telling them apart would turn the whitelist into
      # a directory of what the host stores.
      def resolve_commentable
        type = params[:commentable_type].presence
        id = params[:commentable_id].presence
        return if type.nil? || id.nil?

        _, target = Bali.block_editor_commentables.find { |key, _| key.to_s == type }
        return if target.nil?
        return target.call(id) if target.respond_to?(:call)

        # A String is the reload-safe way to name a model from an initializer: storing
        # the class object itself pins the copy Zeitwerk throws away on the next
        # reload. This constantizes CONFIG the host wrote, never `commentable_type` —
        # that only ever gets compared to the whitelist's keys.
        klass = target.is_a?(String) ? target.safe_constantize : target
        klass&.find_by(id: id)
      end

      def authorize_comments!
        return if Bali.block_editor_comments_authorize.call(self, current_comments_user_id, @commentable)

        head :forbidden
      end

      def threads
        BlockEditorThread.where(commentable: @commentable)
      end

      def set_thread
        @thread = threads.find(params[thread_id_param])
      end

      # `BlockEditorThreadsController` gets `:id`, the nested controllers get the
      # `resources :block_editor_threads` prefix.
      def thread_id_param
        :block_editor_thread_id
      end

      # BlockNote sends a comment body as a JSON ARRAY of blocks, and strong parameters
      # drop non-scalar values silently — `params.permit(:body)` returns nothing at all
      # here. Everything this reaches is stored as opaque JSON and never interpolated
      # server-side.
      #
      # The array branch is not decoration: Rails wraps each object inside it in its own
      # `ActionController::Parameters`, and handing those to a json column only works
      # because `as_json` happens to delegate to the underlying hash. Converting here
      # means what gets stored is a plain Hash, which is what every reader assumes.
      def permit_json(value)
        case value
        when Array then value.map { |item| permit_json(item) }
        when ActionController::Parameters then value.to_unsafe_h
        else value
        end
      end

      def render_not_found
        head :not_found
      end

      def render_invalid(error)
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_content
      end

      def render_conflict
        head :conflict
      end
    end
  end
end
