# frozen_string_literal: true

class BlockEditorComment < ApplicationRecord
  belongs_to :block_editor_thread, touch: true
  has_many :block_editor_reactions, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }

  def soft_delete!
    update!(body: nil, deleted_at: Time.current)
  end

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

  def grouped_reactions
    block_editor_reactions
      .group_by(&:emoji)
      .map do |emoji, reactions|
        {
          emoji: emoji,
          created_at: reactions.map(&:created_at).min.iso8601,
          user_ids: reactions.map(&:user_id)
        }
      end
  end
end
