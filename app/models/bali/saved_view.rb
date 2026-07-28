# frozen_string_literal: true

module Bali
  # B2 — vista guardada del DataTable: una combinación de filtros CON NOMBRE, del dueño
  # (`owner` polimórfico — hoy el usuario; la fase 2 hará owner=equipo/rol sin tocar el
  # esquema) y de UN listado (`storage_id`). Este modelo + su Store son la implementación
  # DEFAULT del contrato `saved_views_store` del FilterForm — una app puede seguir pasando
  # su propio store y este modelo ni se carga.
  class SavedView < ApplicationRecord
    # El contrato del payload lo define el FilterForm; el modelo no confía en que la UI
    # mande solo lo pactado y recorta todo lo demás al asignar.
    PAYLOAD_KEYS = Bali::FilterForm::SavedViewsConfiguration::PAYLOAD_KEYS
    NAME_MAX_LENGTH = 60

    belongs_to :owner, polymorphic: true

    validates :storage_id, presence: true
    validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH },
                     uniqueness: { scope: %i[owner_type owner_id storage_id] }

    # Atajo para la línea de adopción en un controller:
    #   saved_views_store: Bali::SavedView.store_for(current_user, "users_index")
    def self.store_for(owner, storage_id)
      Store.new(owner: owner, storage_id: storage_id)
    end

    # La UI de Bali envía el payload como JSON serializado en un hidden (las columnas las
    # inyecta Stimulus al enviar); también acepta un Hash directo (tests, consola).
    def payload=(value)
      value = JSON.parse(value) if value.is_a?(String)
      super(value.is_a?(Hash) ? value.slice(*PAYLOAD_KEYS) : {})
    rescue JSON::ParserError
      super({})
    end
  end
end
