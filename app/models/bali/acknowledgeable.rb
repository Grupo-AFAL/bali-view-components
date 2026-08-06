# frozen_string_literal: true

module Bali
  # #709 — "leí y confirmo" para un modelo del host:
  #
  #   class Document < ApplicationRecord
  #     include Bali::Acknowledgeable
  #   end
  #
  #   @document.acknowledge(user: current_user)
  #   @document.acknowledged_by?(current_user) # => true
  #
  # No hay macro que configurar: lo único que el concern le pregunta al modelo es
  # `version_label`, y se lo pregunta con `try`, así que un modelo sin versiones funciona
  # igual (la firma queda con `version_label` nil).
  #
  # El engine NO trae controller en la v1 a propósito: el valor del endpoint de
  # gobierno-corporativo está en un `turbo_stream` que renderiza una vista DEL HOST, y un
  # controller del engine no puede responder eso sin conocer el partial del host. La receta
  # de 20 líneas está en docs/guides/engine-models.md.
  module Acknowledgeable
    extend ActiveSupport::Concern

    included do
      has_many :acknowledgments, as: :acknowledgeable,
                                 class_name: "Bali::Acknowledgment", dependent: :destroy
    end

    def acknowledged_by?(user)
      acknowledgments.exists?(user: user)
    end

    # Idempotente: confirmar dos veces la MISMA versión devuelve la firma que ya existía,
    # sin tocarla — el `acknowledged_at` original sobrevive, que es justamente lo que hace
    # que esto sirva como evidencia.
    #
    # Cuando `version_label` cambió, en cambio, esto es un acto NUEVO: la persona está
    # firmando otro texto. Se actualiza la etiqueta **y la fecha**.
    #
    # OJO, aquí se separa de gobierno-corporativo (`acknowledged_at ||= Time.current`, que
    # conserva la fecha vieja al re-firmar): esa fila termina diciendo que alguien firmó la
    # v2.0 en una fecha en la que la v2.0 todavía no existía. Con solo dos columnas la
    # única lectura coherente es "acknowledged_at es cuándo firmó version_label", así que
    # se actualizan juntas. La guía de migración lo nombra.
    def acknowledge(user:, content_version_id: nil)
      ack = acknowledgments.find_or_initialize_by(user: user)
      return ack if ack.persisted? && ack.version_label == acknowledgeable_version_label

      ack.acknowledged_at = Time.current
      ack.version_label = acknowledgeable_version_label
      ack.content_version_id = content_version_id || derived_content_version_id
      ack.save!
      ack
    rescue ActiveRecord::RecordNotUnique
      # Dos clics a la vez: el índice único rechaza el segundo INSERT. La fila que ganó
      # dice lo mismo que íbamos a escribir, así que devolverla ES el resultado correcto.
      acknowledgments.find_by!(user: user)
    end

    private

    def acknowledgeable_version_label
      try(:version_label)
    end

    # Se llena solo cuando el registro además lleva historial de contenido (#707). Con `try`
    # porque instalar el libro de firmas no obliga a instalar el historial: sin él esto es
    # nil y la columna se queda vacía, que es exactamente por lo que no tiene foreign key.
    def derived_content_version_id
      try(:content_versions)&.last&.id
    end
  end
end
