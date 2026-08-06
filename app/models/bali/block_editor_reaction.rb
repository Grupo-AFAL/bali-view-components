# frozen_string_literal: true

module Bali
  # #706 — one user's emoji reaction on one comment. The database index is the real
  # guard against a double-tap; the validation just turns the race into a readable
  # error instead of a 500.
  class BlockEditorReaction < ApplicationRecord
    belongs_to :comment,
               class_name: "Bali::BlockEditorComment",
               foreign_key: :block_editor_comment_id,
               inverse_of: :reactions,
               touch: true

    validates :emoji, presence: true
    validates :user_id, presence: true
    validates :emoji, uniqueness: { scope: %i[block_editor_comment_id user_id] }
  end
end
