# frozen_string_literal: true

module Bali
  # #706 — a BlockEditor comment thread, anchored to a host record through the
  # polymorphic `commentable`. Flat name, not `Bali::BlockEditor::Thread`: that
  # namespace belongs to the component in app/components, and the flat precedent is
  # already set by `Bali::BlockEditorUploadsController` / `Bali::BlockEditorHelper`.
  #
  # A thread ALWAYS belongs to something. `RESTThreadStore` lists threads from one
  # base URL, so a nullable commentable means "every thread in the database" is one
  # forgotten query parameter away — which is exactly the leak this engine exists to
  # fix. The controllers require the commentable on every action for the same reason.
  class BlockEditorThread < ApplicationRecord
    belongs_to :commentable, polymorphic: true

    # Ordered by creation because `comments.first` is load-bearing: it decides who may
    # delete the thread, mirroring BlockNote's own `DefaultThreadStoreAuth`.
    # Soft-deleted comments stay in the list (the JSON contract carries them with a
    # null body), so the first author does not change when they delete their comment.
    has_many :comments, -> { order(:created_at) },
             class_name: "Bali::BlockEditorComment",
             foreign_key: :block_editor_thread_id,
             inverse_of: :thread,
             dependent: :destroy

    scope :with_comments, -> { includes(comments: :reactions) }

    # Same bound as BlockEditorComment::MAX_METADATA_BYTES, for the same reason:
    # `metadata` is a client round-trip channel and must not be an unbounded write.
    MAX_METADATA_BYTES = 16 * 1024

    validate :metadata_within_bounds

    def resolve!(user_id)
      update!(resolved: true, resolved_by: user_id, resolved_updated_at: Time.current)
    end

    def unresolve!
      update!(resolved: false, resolved_by: nil, resolved_updated_at: Time.current)
    end

    # Who BlockNote lets delete the thread client-side, resolved server-side.
    def author_id
      comments.first&.user_id
    end

    # FROZEN CONTRACT. `RESTThreadStore._normalizeThread` reads these exact keys
    # (app/components/bali/block_editor/RESTThreadStore.js) and every host's editor
    # breaks at once if one is renamed. `test/bali/block_editor_json_contract_test.rb`
    # fails the build on any change here.
    #
    # `as_json` rather than a serializer gem so the engine stays dependency-free;
    # a host app is free to use Blueprinter in its own controllers.
    def as_json(_options = {})
      {
        id: id,
        resolved: resolved,
        resolved_by: resolved_by,
        resolved_updated_at: resolved_updated_at&.iso8601,
        metadata: metadata || {},
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601,
        comments: comments.map(&:as_json)
      }
    end

    private

    def metadata_within_bounds
      return if metadata.nil?

      return unless metadata.to_json.bytesize > MAX_METADATA_BYTES

      errors.add(:metadata, "is too large (maximum is #{MAX_METADATA_BYTES} bytes)")
    end
  end
end
