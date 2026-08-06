# frozen_string_literal: true

module Bali
  # #708 — una referencia embebida en contenido BlockNote, materializada como fila para que
  # el host pueda preguntar "¿quién menciona a este registro?" sin escanear JSON.
  #
  # Las escribe `Bali::EntityReferenceable` con un diff mínimo en cada guardado del editor;
  # nadie las crea a mano. `referenceable` es `optional: true` porque una referencia a un
  # registro borrado SIGUE siendo válida: es exactamente el chip roto que el JS pinta.
  class EntityReference < ApplicationRecord
    belongs_to :record, polymorphic: true
    belongs_to :referenceable, polymorphic: true, optional: true

    validates :referenceable_type, presence: true
    validates :referenceable_id, presence: true,
                                 uniqueness: { scope: %i[record_type record_id referenceable_type] }

    scope :of_type, ->(type) { where(referenceable_type: type) }

    # La inversa polimórfica: las referencias QUE APUNTAN a este registro. Sirve para
    # cualquier modelo, incluya o no el concern (un usuario referenciado no tiene por qué
    # saber nada de BlockNote).
    scope :to, ->(entity) { where(referenceable_type: entity.class.name, referenceable_id: entity.id) }

    # Alcanzabilidad según el registry del host: sin tipo registrado, un referido presente
    # basta. Requiere `referenceable` cargado (los paneles usan `includes(:referenceable)`).
    def broken?
      Bali.entity_reference_unreachable?(referenceable_type, referenceable)
    end

    def reachable? = !broken?
  end
end
