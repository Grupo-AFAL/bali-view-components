# frozen_string_literal: true

module Bali
  # #709 — una firma: esta persona confirmó haber leído esto. No se crea a mano; la produce
  # `Bali::Acknowledgeable#acknowledge`, que es quien sabe resolver la idempotencia y la
  # etiqueta de versión.
  #
  # No hay whitelist de `acknowledgeable_type` en el modelo (gobierno-corporativo sí la
  # tiene). Aquí sobra: el engine no expone controller en la v1, así que el tipo nunca llega
  # de una request — lo pone el propio modelo del host al llamar `acknowledge`. Si algún día
  # entra un endpoint, la whitelist va en la config del controller, como en #707, y no en el
  # modelo: un `inclusion:` sobre una constante no se puede configurar por app.
  class Acknowledgment < ApplicationRecord
    belongs_to :acknowledgeable, polymorphic: true
    belongs_to :user, polymorphic: true

    validates :acknowledged_at, presence: true
    validates :user_id, uniqueness: {
      scope: %i[acknowledgeable_type acknowledgeable_id user_type]
    }
  end
end
