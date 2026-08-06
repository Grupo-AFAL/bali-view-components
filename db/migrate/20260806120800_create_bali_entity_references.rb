# frozen_string_literal: true

# #708 — referencias de entidades embebidas en contenido BlockNote. `record` es el que
# CONTIENE la referencia (un documento, una tarea, lo que el host marque con
# Bali::EntityReferenceable) y `referenceable` es el referido. Ambos polimórficos: el engine
# no conoce ninguna de las dos clases.
#
# SIN foreign key en `referenceable` A PROPÓSITO: una referencia a un registro borrado debe
# sobrevivir para pintarse como chip roto (`broken: true`), que es justo lo que el JS espera.
# Un FK con ON DELETE la borraría en silencio y el lector perdería la señal.
class CreateBaliEntityReferences < ActiveRecord::Migration[7.0]
  def change
    create_table :bali_entity_references do |t|
      # Los índices default de `references` serían redundantes: el único de abajo cubre el
      # prefijo [record_type, record_id] y el de lookup cubre [referenceable_type, referenceable_id].
      t.references :record, polymorphic: true, null: false, index: false
      t.references :referenceable, polymorphic: true, null: false, index: false
      # El nombre del referido AL MOMENTO de escribirlo: sirve para listar referencias sin
      # resolver cada tipo, y es lo único que queda cuando el registro referido desaparece.
      t.string :reference_text

      t.timestamps
    end

    # Nombre corto: el autogenerado con cuatro columnas rebasa el límite de identificadores de PG.
    add_index :bali_entity_references,
              %i[record_type record_id referenceable_type referenceable_id],
              unique: true, name: "index_bali_entity_references_uniqueness"

    # La inversa (`incoming_references`): quién referencia a este registro.
    add_index :bali_entity_references, %i[referenceable_type referenceable_id],
              name: "index_bali_entity_references_on_referenceable"
  end
end
