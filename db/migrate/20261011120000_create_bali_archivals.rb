# frozen_string_literal: true

class CreateBaliArchivals < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_archivals do |t|
      # No index of its own: `archival`, `archived` and `not_archived` ask for the current row,
      # which the partial unique index below serves. `archivals` (the history) and
      # `dependent: :destroy` look up by record alone and scan, at a few rows per record.
      t.references :archivable, polymorphic: true, null: false, index: false
      t.references :archived_by, polymorphic: true, index: false
      t.string :reason
      t.text :note
      t.references :successor, polymorphic: true, index: false
      t.datetime :unarchived_at
      t.references :unarchived_by, polymorphic: true, index: false

      t.timestamps
    end

    # At most one current archival per record, enforced where two concurrent requests cannot
    # both pass it. A reopened row (`unarchived_at` set) stays out of the index as history.
    add_index :bali_archivals, %i[archivable_type archivable_id],
              unique: true, where: "unarchived_at IS NULL", name: "index_bali_archivals_current"
    add_index :bali_archivals, %i[successor_type successor_id],
              name: "index_bali_archivals_on_successor"
  end
end
