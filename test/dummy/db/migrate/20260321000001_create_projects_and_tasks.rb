# frozen_string_literal: true

class CreateProjectsAndTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.integer :position, default: 0, null: false
      t.integer :priority, default: 0, null: false
      t.timestamps
    end

    add_index :tasks, [:project_id, :status, :position]
  end
end
