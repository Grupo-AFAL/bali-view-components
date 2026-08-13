# frozen_string_literal: true

# #706 — the three tables behind the BlockEditor's inline comments (a host installs
# them with `bin/rails bali:install:migrations`).
#
# Column names are NOT free here. An app that already ran the reference
# implementation (`block_editor_threads` / `block_editor_comments` /
# `block_editor_reactions`) adopts the engine with three `rename_table` calls and no
# data copy — which only works while every column keeps the name it had. That is why
# the foreign keys read `block_editor_thread_id` and `block_editor_comment_id`
# instead of the shorter `thread_id`/`comment_id` the association names suggest.
# See the migration guide in docs/guides/engines.md.
#
# The dummy registers these tables by hand in spec/dummy/db/schema.rb, the way it did
# for bali_saved_views — it never runs `bali:install:migrations`. Its schema `version:`
# has to reach this timestamp too, or every `bin/rails` call in spec/dummy reports a
# pending migration it has no path to run.
class CreateBaliBlockEditorComments < ActiveRecord::Migration[7.0]
  def change
    # jsonb only exists on Postgres; the engine's dummy (and any sqlite host) uses
    # json. Same conditional as CreateBaliSavedViews.
    json = connection.adapter_name.match?(/postg/i) ? :jsonb : :json

    create_table :bali_block_editor_threads do |t|
      # null: false on purpose. `RESTThreadStore` lists threads from a single base
      # URL, so a thread that belongs to nothing is a thread every host record can
      # read. The controllers refuse to answer without a commentable for the same
      # reason.
      t.references :commentable, polymorphic: true, null: false
      t.boolean :resolved, default: false, null: false
      t.string :resolved_by
      t.datetime :resolved_updated_at
      t.public_send(json, :metadata, default: {})

      t.timestamps
    end

    create_table :bali_block_editor_comments do |t|
      t.references :block_editor_thread, null: false,
                                         foreign_key: { to_table: :bali_block_editor_threads },
                                         index: { name: "index_bali_block_editor_comments_on_thread_id" }
      t.string :user_id, null: false
      t.public_send(json, :body)
      t.public_send(json, :metadata, default: {})
      t.datetime :deleted_at

      t.timestamps
    end

    create_table :bali_block_editor_reactions do |t|
      # The unique index below starts with this column, so the reference's own index
      # would be redundant.
      t.references :block_editor_comment, null: false, index: false,
                                          foreign_key: { to_table: :bali_block_editor_comments }
      t.string :user_id, null: false
      t.string :emoji, null: false

      t.timestamps
    end

    # One reaction per (comment, user, emoji) — the database, not the validation, is
    # what makes a double-tap impossible.
    add_index :bali_block_editor_reactions, %i[block_editor_comment_id user_id emoji],
              unique: true, name: "idx_bali_reactions_comment_user_emoji"
  end
end
