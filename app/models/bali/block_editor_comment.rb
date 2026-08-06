# frozen_string_literal: true

module Bali
  # #706 — one comment inside a `Bali::BlockEditorThread`.
  #
  # `user_id` is a plain string, not a polymorphic author: that is the contract the
  # JS already froze. The editor resolves a display name client-side from
  # `comments[:users]` or `comments[:users_url]`, so nothing server-side ever joins
  # on this column — see docs/guides/engines.md.
  class BlockEditorComment < ApplicationRecord
    belongs_to :thread,
               class_name: "Bali::BlockEditorThread",
               foreign_key: :block_editor_thread_id,
               inverse_of: :comments,
               touch: true

    has_many :reactions,
             class_name: "Bali::BlockEditorReaction",
             foreign_key: :block_editor_comment_id,
             inverse_of: :comment,
             dependent: :destroy

    scope :active, -> { where(deleted_at: nil) }

    # Bounds for client-supplied JSON. Real editor payloads are a few KB; the caps
    # exist so the columns cannot become unbounded write primitives (measured
    # pre-fix: a 500 KB body and 300 KB of metadata stored verbatim).
    MAX_BODY_BYTES = 256 * 1024
    MAX_METADATA_BYTES = 16 * 1024

    validates :user_id, presence: true
    validates :body, presence: true, unless: :soft_deleted?
    validate :body_within_bounds
    validate :metadata_within_bounds

    def soft_deleted?
      deleted_at.present?
    end

    # Soft, not hard: BlockNote keeps rendering the comment as a tombstone, and the
    # thread's first author (who may delete the thread) has to survive its own
    # comment being deleted.
    def soft_delete!
      update!(body: nil, deleted_at: Time.current)
    end

    # FROZEN CONTRACT — `RESTThreadStore._normalizeComment`. See BlockEditorThread#as_json.
    def as_json(_options = {})
      {
        id: id,
        user_id: user_id,
        body: body,
        metadata: metadata || {},
        deleted_at: deleted_at&.iso8601,
        created_at: created_at.iso8601,
        updated_at: updated_at.iso8601,
        reactions: grouped_reactions
      }
    end

    private

    def body_within_bounds
      return if body.nil?

      errors.add(:body, "is too large (maximum is #{MAX_BODY_BYTES} bytes)") if body.to_json.bytesize > MAX_BODY_BYTES
    end

    def metadata_within_bounds
      return if metadata.nil?

      return unless metadata.to_json.bytesize > MAX_METADATA_BYTES

      errors.add(:metadata, "is too large (maximum is #{MAX_METADATA_BYTES} bytes)")
    end

    # One row per (comment, user, emoji) in the table, one entry per emoji on the
    # wire: `{ emoji:, created_at:, user_ids: [] }` is what the editor renders.
    def grouped_reactions
      reactions.group_by(&:emoji).map do |emoji, rows|
        {
          emoji: emoji,
          created_at: rows.map(&:created_at).min.iso8601,
          user_ids: rows.map(&:user_id)
        }
      end
    end
  end
end
