# frozen_string_literal: true

module Bali
  # #708 — marca un modelo cuyo contenido BlockNote puede embeber referencias a otras
  # entidades (`@`/`#` en el editor). Al guardar, las referencias del JSON se materializan
  # en `bali_entity_references`.
  #
  #   class Document < ApplicationRecord
  #     include Bali::EntityReferenceable
  #     references_entities_in :body   # opcional; default :content
  #   end
  #
  # Qué tipos son referenciables lo decide `Bali.entity_reference_types` (el mismo registry
  # que alimenta el buscador y el `references_config` del JS): una referencia a un tipo no
  # registrado se ignora al extraer, así que un tipo dado de baja deja de materializarse sin
  # migración de datos.
  module EntityReferenceable
    extend ActiveSupport::Concern

    included do
      has_many :entity_references, class_name: "Bali::EntityReference",
                                   as: :record, dependent: :destroy

      # El nombre de la columna JSON, para que `references_entities_in` no tenga que
      # redefinir el callback. `instance_writer: false`: es configuración de la clase.
      class_attribute :entity_reference_attribute, instance_writer: false, default: :content

      # SOLO cuando el contenido cambió. El editor autosalva, y sin esta guarda cada
      # guardado borraría y recrearía las referencias del documento entero.
      after_save :extract_entity_references!, if: :entity_reference_source_changed?
    end

    class_methods do
      # Declara qué columna guarda el JSON de BlockNote cuando no es `content`.
      def references_entities_in(attribute)
        self.entity_reference_attribute = attribute.to_sym
      end

      # Los registros de ESTA clase que referencian a `entity`.
      def referencing(entity)
        joins(:entity_references)
          .where(bali_entity_references: { referenceable_type: entity.class.name,
                                           referenceable_id: entity.id })
          .distinct
      end
    end

    # Las referencias que apuntan a este registro (la inversa de `entity_references`).
    def incoming_references
      Bali::EntityReference.to(self)
    end

    # Diff mínimo contra las filas existentes: borra las que ya no están, inserta las
    # nuevas, y NO TOCA las que siguen — sus ids sobreviven a cada autosave, que es lo que
    # permite colgar cosas de una referencia (y lo que un delete_all + create! rompería).
    def extract_entity_references!
      extracted = extracted_entity_references
      extracted_keys = extracted.map { |ref| [ ref[:type], ref[:id].to_i ] }.to_set

      current = entity_references.pluck(:id, :referenceable_type, :referenceable_id)
      stale_ids = current.reject { |(_, type, ref_id)| extracted_keys.include?([ type, ref_id ]) }.map(&:first)
      current_keys = current.map { |(_, type, ref_id)| [ type, ref_id ] }.to_set
      new_rows = extracted.reject { |ref| current_keys.include?([ ref[:type], ref[:id].to_i ]) }

      transaction do
        entity_references.where(id: stale_ids).delete_all if stale_ids.any?
        insert_entity_references(new_rows) if new_rows.any?
      end
    end

    private

    def entity_reference_source_changed?
      saved_change_to_attribute?(self.class.entity_reference_attribute)
    end

    # El contenido lo escribe el editor: nada garantiza que un nodo apunte a un tipo vivo, ni
    # a un id que quepa en la columna, ni que el documento traiga una cantidad razonable de
    # referencias. Los tres límites de abajo existen porque este callback corre DENTRO del
    # `update!` del host — lo que aquí explote se lleva el guardado del usuario con él.
    #
    #   - fuera del registry              → se ignora (un tipo dado de baja deja de indexarse)
    #   - id no numérico o mayor a bigint → se ignora (un `to_i` guardaría basura, y un id de
    #                                       20 dígitos levanta RangeError y aborta el save)
    #   - más de MAX_REFERENCES           → se corta (un documento con 12k referencias rebasa
    #                                       el techo de bind params de PG en un solo insert)
    NUMERIC_ID = /\A\d{1,19}\z/
    BIGINT_MAX = (2**63) - 1
    MAX_REFERENCES = 500
    MAX_REFERENCE_TEXT = 255

    def extracted_entity_references
      content = public_send(self.class.entity_reference_attribute)
      return [] if content.blank?

      registered = Bali.entity_reference_types.keys.map(&:to_s)
      Bali::BlockNote::Text
        .entity_references(Bali::BlockNote::Text.normalize(content))
        .select { |ref| registered.include?(ref[:type]) && storable_id?(ref[:id]) }
        .first(MAX_REFERENCES)
    end

    def storable_id?(id)
      id.match?(NUMERIC_ID) && id.to_i <= BIGINT_MAX
    end

    def insert_entity_references(rows)
      now = Time.current

      # `insert_all` (sin bang) + `unique_by`: dos autosaves solapados del mismo registro leen
      # el mismo `current` y calculan las mismas filas nuevas; con el bang el perdedor de la
      # carrera levanta RecordNotUnique dentro del after_save y tira el guardado legítimo.
      # Saltarse el conflicto ES la semántica del diff — la fila que ya está conserva su id.
      # (`unique_by` necesita Postgres o SQLite; un host en MySQL tendría que sobrescribir esto.)
      entity_references.insert_all(
        rows.map { |ref|
          {
            record_type: self.class.polymorphic_name,
            record_id: id,
            referenceable_type: ref[:type],
            referenceable_id: ref[:id],
            # Texto del cliente, sin validar contra el registro real: se acota para que un
            # `entityName` de 200 KB no se guarde entero. Ver docs/guides/engines.md — es la
            # única parte de esta tabla que NO pasa por `permission_scope`.
            reference_text: ref[:name].to_s.truncate(MAX_REFERENCE_TEXT).presence,
            created_at: now,
            updated_at: now
          }
        },
        unique_by: %i[record_type record_id referenceable_type referenceable_id]
      )
    end
  end
end
