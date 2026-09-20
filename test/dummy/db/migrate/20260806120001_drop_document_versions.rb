# frozen_string_literal: true

# El dummy dejó de tener historial propio: `Document` incluye `Bali::ContentVersionable` y
# sus versiones viven en `bali_content_versions` (#707). Esta tabla se queda sin modelo ni
# controller, y dejarla sería enseñarle al host que copia de aquí un esquema que ya no se usa.
class DropDocumentVersions < ActiveRecord::Migration[8.1]
  def up
    drop_table :document_versions
  end

  def down
    create_table :document_versions do |t|
      t.references :document, null: false, foreign_key: true
      t.json :content, default: []
      t.integer :version_number, null: false
      t.string :author_name, null: false
      t.string :summary
      t.datetime :created_at, null: false
    end
    add_index :document_versions, %i[document_id version_number], unique: true
  end
end
