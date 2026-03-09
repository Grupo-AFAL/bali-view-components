class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :title, null: false
      t.json :content, default: []
      t.integer :status, default: 0, null: false
      t.string :author_name, null: false
      t.timestamps
    end
  end
end
