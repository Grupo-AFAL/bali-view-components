# frozen_string_literal: true

# #709 — the record of "I have read and confirm this". It is a GENERIC SIGNATURE BOOK: both
# the signer (`user`) and the thing signed (`acknowledgeable`) are polymorphic, so a host
# signs documents with `User`, agreements with `Member` or workflow steps with whatever,
# without Bali knowing any of those classes.
#
# A polymorphic `user` is the difference from gobierno-corporativo, where it is a bigint FK
# to `users`. Migrating from there means populating `user_type = 'User'` — see docs/guides/engine-models.md.
class CreateBaliAcknowledgments < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_acknowledgments do |t|
      # The unique index below covers the [acknowledgeable_type, acknowledgeable_id] prefix;
      # the references default index would be redundant.
      t.references :acknowledgeable, polymorphic: true, null: false, index: false
      t.references :user, polymorphic: true, null: false, index: true
      t.datetime :acknowledged_at, null: false
      # `version_label` and not `version_number`: it is the label the host shows
      # people ("2.0"), not the sequential integer of `bali_content_versions`. Sharing
      # the name would make two different things look like the same one.
      t.string :version_label
      # Deliberately NO foreign key: installing the signature book must not force
      # installing the content history (#707). When both are present, the concern fills it
      # in by itself; when not, it stays nil and nothing happens.
      t.bigint :content_version_id

      t.timestamps
    end

    # One signature per person and per thing signed. Re-confirming updates that row, it does
    # not create another — the concern makes it explicit and this index makes it impossible to skip.
    add_index :bali_acknowledgments,
              %i[acknowledgeable_type acknowledgeable_id user_type user_id],
              unique: true, name: "index_bali_acknowledgments_uniqueness"
  end
end
