# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_21_000001) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "block_editor_comments", force: :cascade do |t|
    t.integer "block_editor_thread_id", null: false
    t.json "body"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.json "metadata", default: {}
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["block_editor_thread_id"], name: "index_block_editor_comments_on_block_editor_thread_id"
  end

  create_table "block_editor_reactions", force: :cascade do |t|
    t.integer "block_editor_comment_id", null: false
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["block_editor_comment_id", "user_id", "emoji"], name: "idx_reactions_comment_user_emoji", unique: true
    t.index ["block_editor_comment_id"], name: "index_block_editor_reactions_on_block_editor_comment_id"
  end

  create_table "block_editor_threads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "document_id"
    t.json "metadata", default: {}
    t.boolean "resolved", default: false, null: false
    t.string "resolved_by"
    t.datetime "resolved_updated_at"
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_block_editor_threads_on_document_id"
  end

  create_table "characters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "movie_id", null: false
    t.string "name"
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_characters_on_movie_id"
  end

  create_table "document_versions", force: :cascade do |t|
    t.string "author_name", null: false
    t.json "content", default: []
    t.datetime "created_at", null: false
    t.integer "document_id", null: false
    t.string "summary"
    t.integer "version_number", null: false
    t.index ["document_id", "version_number"], name: "index_document_versions_on_document_id_and_version_number", unique: true
    t.index ["document_id"], name: "index_document_versions_on_document_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "author_name", null: false
    t.json "content", default: []
    t.datetime "created_at", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "form_records", force: :cascade do |t|
    t.boolean "boolean"
    t.datetime "created_at", null: false
    t.decimal "currency"
    t.date "date"
    t.datetime "datetime"
    t.string "email"
    t.date "end_date"
    t.decimal "number"
    t.string "password"
    t.decimal "percentage"
    t.json "polygon_data", default: {}
    t.integer "select"
    t.text "text"
    t.integer "time"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "movies", force: :cascade do |t|
    t.decimal "budget"
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.string "genre"
    t.boolean "indie"
    t.string "name"
    t.decimal "rating"
    t.date "release_date"
    t.text "rich_description"
    t.integer "status", default: 0
    t.text "synopsis"
    t.integer "tenant_id", null: false
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["tenant_id"], name: "index_movies_on_tenant_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "studios", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.integer "founded_year"
    t.string "name"
    t.string "size"
    t.integer "status"
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.integer "priority", default: 0, null: false
    t.integer "project_id", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "status", "position"], name: "index_tasks_on_project_id_and_status_and_position"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "workouts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "workout_start_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "block_editor_comments", "block_editor_threads"
  add_foreign_key "block_editor_reactions", "block_editor_comments"
  add_foreign_key "block_editor_threads", "documents"
  add_foreign_key "characters", "movies"
  add_foreign_key "document_versions", "documents"
  add_foreign_key "movies", "tenants"
  add_foreign_key "tasks", "projects"
end
