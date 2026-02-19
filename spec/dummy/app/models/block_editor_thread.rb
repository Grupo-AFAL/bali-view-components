# frozen_string_literal: true

class BlockEditorThread < ApplicationRecord
  has_many :block_editor_comments, dependent: :destroy

  scope :with_comments, -> { includes(block_editor_comments: :block_editor_reactions) }

  def as_json(_options = {})
    {
      id: id,
      resolved: resolved,
      resolved_by: resolved_by,
      resolved_updated_at: resolved_updated_at&.iso8601,
      metadata: metadata || {},
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      comments: block_editor_comments.sort_by(&:created_at).map(&:as_json)
    }
  end
end
