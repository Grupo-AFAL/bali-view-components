# frozen_string_literal: true

class BlockEditorReaction < ApplicationRecord
  belongs_to :block_editor_comment, touch: true

  validates :emoji, presence: true
  validates :user_id, presence: true
  validates :emoji, uniqueness: { scope: %i[block_editor_comment_id user_id] }
end
