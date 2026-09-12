# frozen_string_literal: true

# #709 — el registro de "leí y confirmo esto". Es un LIBRO DE FIRMAS genérico: tanto el
# firmante (`user`) como lo firmado (`acknowledgeable`) son polimórficos, así que un host
# firma documentos con `User`, convenios con `Member` o pasos de un flujo con lo que sea,
# sin que Bali conozca ninguna de esas clases.
#
# `user` polimórfico es la diferencia con gobierno-corporativo, donde es un FK bigint a
# `users`. Migrar desde ahí es poblar `user_type = 'User'` — ver docs/guides/engine-models.md.
class CreateBaliAcknowledgments < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_acknowledgments do |t|
      # El índice único de abajo cubre el prefijo [acknowledgeable_type, acknowledgeable_id];
      # el índice default del references sería redundante.
      t.references :acknowledgeable, polymorphic: true, null: false, index: false
      t.references :user, polymorphic: true, null: false, index: true
      t.datetime :acknowledged_at, null: false
      # `version_label` y no `version_number`: es la etiqueta que el host le enseña a la
      # gente ("2.0"), no el entero correlativo de `bali_content_versions`. Compartir el
      # nombre haría que dos cosas distintas parecieran la misma.
      t.string :version_label
      # A propósito SIN foreign key: instalar el libro de firmas no puede obligar a
      # instalar el historial de contenido (#707). Cuando ambos están, el concern lo llena
      # solo; cuando no, se queda en nil y no pasa nada.
      t.bigint :content_version_id

      t.timestamps
    end

    # Una firma por persona y por cosa firmada. Re-confirmar actualiza esa fila, no crea
    # otra — el concern lo hace explícito y este índice lo vuelve imposible de saltarse.
    add_index :bali_acknowledgments,
              %i[acknowledgeable_type acknowledgeable_id user_type user_id],
              unique: true, name: "index_bali_acknowledgments_uniqueness"
  end
end
