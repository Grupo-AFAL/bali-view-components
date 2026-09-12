# frozen_string_literal: true

# Dependencies between tasks feed the Gantt island's arrows and the fake CPM
# of the reference schedule endpoint (#705). predecessor → successor with an
# optional lag in days, exactly the shape of the contract's `dependencies`.
class CreateTaskDependencies < ActiveRecord::Migration[8.0]
  def change
    create_table :task_dependencies do |t|
      t.references :predecessor, null: false, foreign_key: { to_table: :tasks }
      t.references :successor, null: false, foreign_key: { to_table: :tasks }
      t.integer :lag_days, default: 0, null: false
      t.timestamps
    end

    add_index :task_dependencies, %i[predecessor_id successor_id], unique: true
  end
end
