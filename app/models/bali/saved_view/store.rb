# frozen_string_literal: true

module Bali
  class SavedView
    # Implementación default del contrato `saved_views_store` (list/find/save/delete),
    # scoped a UN dueño y UN listado (storage_id). El FilterForm solo lee (list/find);
    # save/delete los usa Bali::SavedViewsController. "Vistas compartidas por equipo"
    # (fase 2) es OTRA clase con este mismo contrato — el FilterForm no se entera.
    class Store
      def initialize(owner:, storage_id:)
        @owner = owner
        @storage_id = storage_id
      end

      def list = scope.order(:name).to_a

      def find(id) = scope.find_by(id: id)

      # Upsert por nombre: guardar "Míos" dos veces actualiza la vista, no duplica.
      def save(name:, payload:)
        view = scope.find_or_initialize_by(name: name)
        view.update!(payload: payload)
        view
      end

      def delete(id) = scope.find_by(id: id)&.destroy!

      private

      def scope = SavedView.where(owner: @owner, storage_id: @storage_id)
    end
  end
end
