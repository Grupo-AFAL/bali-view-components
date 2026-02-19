# frozen_string_literal: true

class BlockEditorThread < ApplicationRecord
  has_many :block_editor_comments, -> { order(:created_at) }, inverse_of: :block_editor_thread, dependent: :destroy

  scope :with_comments, -> { includes(block_editor_comments: :block_editor_reactions) }

  def resolve!(user_id)
    update!(resolved: true, resolved_by: user_id, resolved_updated_at: Time.current)
  end

  def unresolve!
    update!(resolved: false, resolved_by: nil, resolved_updated_at: Time.current)
  end

  # NOTE: Production apps should use Blueprinter for serialization instead of as_json overrides.
  # as_json is used here to keep this reference implementation dependency-free.
  def as_json(_options = {})
    {
      id: id,
      resolved: resolved,
      resolved_by: resolved_by,
      resolved_updated_at: resolved_updated_at&.iso8601,
      metadata: metadata || {},
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      comments: block_editor_comments.map(&:as_json)
    }
  end
end
