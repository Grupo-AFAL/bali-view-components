# frozen_string_literal: true

class CreateBlockEditorComments < ActiveRecord::Migration[8.0]
  def change
    create_table :block_editor_threads do |t|
      t.boolean :resolved, default: false, null: false
      t.string :resolved_by
      t.datetime :resolved_updated_at
      t.json :metadata, default: {}

      t.timestamps
    end

    create_table :block_editor_comments do |t|
      t.references :block_editor_thread, null: false, foreign_key: true
      t.string :user_id, null: false
      t.json :body
      t.json :metadata, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    create_table :block_editor_reactions do |t|
      t.references :block_editor_comment, null: false, foreign_key: true
      t.string :user_id, null: false
      t.string :emoji, null: false

      t.timestamps
    end

    add_index :block_editor_reactions, %i[block_editor_comment_id user_id emoji],
              unique: true, name: 'idx_reactions_comment_user_emoji'
  end
end
