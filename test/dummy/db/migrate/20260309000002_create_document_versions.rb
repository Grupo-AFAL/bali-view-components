class CreateDocumentVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :document_versions do |t|
      t.references :document, null: false, foreign_key: true
      t.json :content, default: []
      t.integer :version_number, null: false
      t.string :author_name, null: false
      t.string :summary
      t.datetime :created_at, null: false
    end
    add_index :document_versions, [:document_id, :version_number], unique: true
  end
end
