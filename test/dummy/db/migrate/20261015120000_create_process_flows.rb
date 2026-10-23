# frozen_string_literal: true

# Reference host for Bali::BpmnEditor (#1489): one row per flow, the whole
# document in a JSON column and a version for the save contract's 409.
class CreateProcessFlows < ActiveRecord::Migration[8.1]
  def change
    create_table :process_flows do |t|
      t.string :name, null: false
      t.json :document, null: false, default: {}
      t.integer :version, null: false, default: 1
      t.datetime :finalized_at
      t.timestamps
    end
  end
end
