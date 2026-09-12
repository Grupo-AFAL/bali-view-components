# frozen_string_literal: true

# #707 — historial de contenido del engine documental. La tabla es GENÉRICA a propósito:
# `record` polimórfico, así que un documento, una política o una nota comparten historial
# sin que Bali conozca ninguno de esos modelos (`Bali.content_versionables` decide cuáles
# se exponen por HTTP).
#
# `author` es polimórfico y OPCIONAL, `author_name` es obligatorio y está denormalizado:
# el JSON que consume `document_editor/index.js` sirve `author_name` (contrato congelado
# en las betas de v3.0), y el FK habilita "mis versiones"/auditoría sin migración futura.
# Un host sin modelo de usuario —o con ids string, como los comentarios del BlockEditor—
# deja `author` en nil y sigue funcionando.
class CreateBaliContentVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_content_versions do |t|
      # El índice único de abajo cubre el prefijo [record_type, record_id]; el índice
      # default del references sería redundante.
      t.references :record, polymorphic: true, null: false, index: false
      # jsonb solo existe en Postgres; el dummy del engine (y cualquier host sqlite) usa
      # json. Mismo criterio que la migración de saved_views.
      if connection.adapter_name.match?(/postg/i)
        t.jsonb :content
        t.jsonb :metadata, null: false, default: {}
      else
        t.json :content
        t.json :metadata, null: false, default: {}
      end
      t.integer :version_number, null: false
      t.references :author, polymorphic: true, null: true, index: false
      t.string :author_name, null: false
      # Un resumen es una línea. El límite es el cinturón del tirante que ya pone el modelo
      # (`Bali::ContentVersion::SUMMARY_MAX_LENGTH`): sin él, `summary` es texto ilimitado
      # que llega de un formulario del host.
      t.string :summary, limit: 255

      t.timestamps
    end

    # La auditoría que promete el comentario de arriba ("mis versiones") filtra por el par
    # del autor, y sin este índice sería un full scan de toda la tabla.
    add_index :bali_content_versions, %i[author_type author_id],
              name: "index_bali_content_versions_on_author"

    # Nombre corto: el autogenerado con estas tres columnas rebasa el límite de
    # identificadores de PG.
    add_index :bali_content_versions, %i[record_type record_id version_number],
              unique: true, name: "index_bali_content_versions_uniqueness"
  end
end
