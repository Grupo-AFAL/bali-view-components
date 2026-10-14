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

ActiveRecord::Schema[8.1].define(version: 2026_10_11_120000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bali_acknowledgments", force: :cascade do |t|
    t.string "acknowledgeable_type", null: false
    t.integer "acknowledgeable_id", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.datetime "acknowledged_at", null: false
    t.string "version_label"
    t.bigint "content_version_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acknowledgeable_type", "acknowledgeable_id", "user_type", "user_id"], name: "index_bali_acknowledgments_uniqueness", unique: true
    t.index ["user_type", "user_id"], name: "index_bali_acknowledgments_on_user"
  end

  create_table "bali_archivals", force: :cascade do |t|
    t.string "archivable_type", null: false
    t.integer "archivable_id", null: false
    t.string "archived_by_type"
    t.integer "archived_by_id"
    t.string "reason"
    t.text "note"
    t.string "successor_type"
    t.integer "successor_id"
    t.datetime "unarchived_at"
    t.string "unarchived_by_type"
    t.integer "unarchived_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["archivable_type", "archivable_id"], name: "index_bali_archivals_current", unique: true, where: "unarchived_at IS NULL"
    t.index ["archivable_type", "archivable_id"], name: "index_bali_archivals_on_archivable"
    t.index ["successor_type", "successor_id"], name: "index_bali_archivals_on_successor"
  end

  create_table "bali_block_editor_comments", force: :cascade do |t|
    t.integer "block_editor_thread_id", null: false
    t.string "user_id", null: false
    t.json "body"
    t.json "metadata", default: {}
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["block_editor_thread_id"], name: "index_bali_block_editor_comments_on_thread_id"
  end

  create_table "bali_block_editor_reactions", force: :cascade do |t|
    t.integer "block_editor_comment_id", null: false
    t.string "user_id", null: false
    t.string "emoji", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["block_editor_comment_id", "user_id", "emoji"], name: "idx_bali_reactions_comment_user_emoji", unique: true
  end

  create_table "bali_block_editor_threads", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.integer "commentable_id", null: false
    t.boolean "resolved", default: false, null: false
    t.string "resolved_by"
    t.datetime "resolved_updated_at"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_bali_block_editor_threads_on_commentable"
  end

  create_table "bali_content_versions", force: :cascade do |t|
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.json "content"
    t.json "metadata", default: {}, null: false
    t.integer "version_number", null: false
    t.string "author_type"
    t.integer "author_id"
    t.string "author_name", null: false
    t.string "summary", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_bali_content_versions_on_author"
    t.index ["record_type", "record_id", "version_number"], name: "index_bali_content_versions_uniqueness", unique: true
  end

  create_table "bali_dashboard_widgets", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.string "context", default: "", null: false
    t.string "dashboard_key", null: false
    t.string "widget_key", null: false
    t.integer "position", null: false
    t.string "size", limit: 32
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "context", "dashboard_key", "position", "widget_key"], name: "index_bali_dashboard_widgets_ordering"
    t.index ["owner_type", "owner_id", "context", "dashboard_key", "widget_key"], name: "index_bali_dashboard_widgets_uniqueness", unique: true
  end

  create_table "bali_entity_references", force: :cascade do |t|
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.string "referenceable_type", null: false
    t.integer "referenceable_id", null: false
    t.string "reference_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "referenceable_type", "referenceable_id"], name: "index_bali_entity_references_uniqueness", unique: true
    t.index ["referenceable_type", "referenceable_id"], name: "index_bali_entity_references_on_referenceable"
  end

  create_table "bali_saved_views", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.string "storage_id", null: false
    t.string "name", null: false
    t.json "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "storage_id", "name"], name: "index_bali_saved_views_uniqueness", unique: true
  end

  create_table "characters", force: :cascade do |t|
    t.string "name"
    t.integer "movie_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.index ["movie_id"], name: "index_characters_on_movie_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "title", null: false
    t.json "content", default: []
    t.integer "status", default: 0, null: false
    t.string "author_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "form_records", force: :cascade do |t|
    t.boolean "boolean"
    t.decimal "currency"
    t.date "date"
    t.datetime "datetime"
    t.date "end_date"
    t.string "email"
    t.decimal "number"
    t.string "password"
    t.decimal "percentage"
    t.text "text"
    t.integer "select"
    t.integer "time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.json "polygon_data", default: {}
  end

  create_table "movies", force: :cascade do |t|
    t.string "name"
    t.string "genre"
    t.integer "status", default: 0
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "indie"
    t.text "synopsis"
    t.text "rich_description"
    t.date "release_date"
    t.decimal "budget"
    t.string "contact_email"
    t.string "website_url"
    t.string "time_zone"
    t.decimal "rating"
    t.date "production_starts_on"
    t.date "production_ends_on"
    t.index ["tenant_id"], name: "index_movies_on_tenant_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "studios", force: :cascade do |t|
    t.string "name"
    t.string "country"
    t.integer "status"
    t.string "size"
    t.integer "founded_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "indie", default: false
  end

  create_table "task_dependencies", force: :cascade do |t|
    t.integer "predecessor_id", null: false
    t.integer "successor_id", null: false
    t.integer "lag_days", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["predecessor_id", "successor_id"], name: "index_task_dependencies_on_predecessor_id_and_successor_id", unique: true
    t.index ["predecessor_id"], name: "index_task_dependencies_on_predecessor_id"
    t.index ["successor_id"], name: "index_task_dependencies_on_successor_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.date "due_date"
    t.string "phase"
    t.boolean "milestone", default: false, null: false
    t.integer "percent_complete"
    t.index ["project_id", "status", "position"], name: "index_tasks_on_project_id_and_status_and_position"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "workouts", force: :cascade do |t|
    t.integer "workout_start_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bali_block_editor_comments", "bali_block_editor_threads", column: "block_editor_thread_id"
  add_foreign_key "bali_block_editor_reactions", "bali_block_editor_comments", column: "block_editor_comment_id"
  add_foreign_key "characters", "movies"
  add_foreign_key "movies", "tenants"
  add_foreign_key "task_dependencies", "tasks", column: "predecessor_id"
  add_foreign_key "task_dependencies", "tasks", column: "successor_id"
  add_foreign_key "tasks", "projects"
end
