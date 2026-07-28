# frozen_string_literal: true

# B2 — vistas guardadas del DataTable: el storage DEFAULT que trae el engine (una app
# instala esto con `bin/rails bali:install:migrations`). `owner` es polimórfico A PROPÓSITO:
# hoy el dueño es el usuario, pero la fase 2 (vistas de equipo/rol) cambia el owner, no el
# esquema. `storage_id` es la misma llave que ya usa la persistencia de filtros del
# FilterForm, así que una vista pertenece a UN listado.
class CreateBaliSavedViews < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_saved_views do |t|
      # El índice único de abajo cubre el prefijo [owner_type, owner_id]; el índice default
      # del references sería redundante.
      t.references :owner, polymorphic: true, null: false, index: false
      t.string :storage_id, null: false
      t.string :name, null: false
      # jsonb solo existe en Postgres; el dummy del engine (y cualquier host sqlite) usa json.
      if connection.adapter_name.match?(/postg/i)
        t.jsonb :payload, null: false, default: {}
      else
        t.json :payload, null: false, default: {}
      end

      t.timestamps
    end

    # Nombre corto: el autogenerado con 4 columnas rebasa el límite de identificadores de PG.
    add_index :bali_saved_views, %i[owner_type owner_id storage_id name],
              unique: true, name: "index_bali_saved_views_uniqueness"
  end
end
