# frozen_string_literal: true

class CreateBaliNotices < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_notices do |t|
      t.references :recipient, polymorphic: true, null: false, index: false
      t.references :actor, polymorphic: true, index: false
      t.references :notifiable, polymorphic: true
      t.string :kind, null: false
      t.text :message, null: false
      t.string :action_url
      t.datetime :read_at
      t.string :idempotency_key

      t.timestamps
    end

    add_index :bali_notices, %i[recipient_type recipient_id created_at],
              name: "index_bali_notices_on_recipient_and_created_at"
    # The counter and the «Nuevo» lookup read only the unread rows, a sliver of each recipient's.
    add_index :bali_notices, %i[recipient_type recipient_id kind],
              where: "read_at IS NULL", name: "index_bali_notices_unread"
    add_index :bali_notices, :idempotency_key, unique: true, where: "idempotency_key IS NOT NULL"

    create_table :bali_notice_deliveries do |t|
      t.bigint :notice_id, null: false, index: { unique: true }
      t.string :mode, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.datetime :delivered_at
      t.datetime :failed_at
      t.string :failure_reason

      t.timestamps
    end

    add_index :bali_notice_deliveries, %i[mode status created_at]
  end
end
