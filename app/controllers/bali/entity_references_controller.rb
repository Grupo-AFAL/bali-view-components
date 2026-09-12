# frozen_string_literal: true

module Bali
  # #708 — los dos endpoints que el `#` del BlockEditor necesita, para TODOS los tipos que
  # el host haya declarado en `Bali.entity_reference_types` (uno por tipo era el diseño que
  # este reemplaza).
  #
  #   GET  bali/entity_references?q=texto   → autocompletado
  #   GET  bali/entity_references?refs[][entityType]=...&refs[][entityId]=...
  #   POST bali/entity_references/resolve   → {refs: [...]} (el que usa el JS al cargar)
  #
  # Autorización: este controller NO hereda los hooks del ApplicationController del host,
  # así que el gate vive adentro y `Bali.entity_references_authorize` DENIEGA por default —
  # sin él, montar el engine publicaría un buscador de los registros de la app. El filtro
  # fino por tipo es `permission_scope:` en cada entrada del registry.
  class EntityReferencesController < ApplicationController
    # Tope de refs por request. El JS manda las del documento abierto, ya deduplicadas, así
    # que un documento real nunca lo roza; existe porque el cuerpo del POST lo escribe el
    # cliente y sin tope una sola request pediría un IN de tamaño arbitrario.
    MAX_REFS = 500

    before_action :authorize_entity_references!

    def index
      return render json: resolver.resolve(permitted_refs) if params[:refs].present?
      return render json: resolver.search(params[:q]) if params[:q].present?

      render json: []
    end

    def resolve
      render json: resolver.resolve(permitted_refs)
    end

    private

    def authorize_entity_references!
      head :forbidden unless Bali.entity_references_authorize.call(self)
    end

    def resolver = EntityReference::Resolver.new(controller: self)

    # Solo las dos llaves del contrato sobreviven: el resto del cuerpo no llega al resolver,
    # que las usa para agrupar y consultar por id.
    def permitted_refs
      Array(params[:refs]).first(MAX_REFS).filter_map { |ref| permit_ref(ref) }
    end

    def permit_ref(ref)
      return ref.permit(:entityType, :entityId).to_h if ref.respond_to?(:permit)
      return ref.stringify_keys.slice("entityType", "entityId") if ref.is_a?(Hash)

      nil
    end
  end
end
