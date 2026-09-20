# frozen_string_literal: true

module Bali
  class SavedView
    # Default implementation of the `saved_views_store` contract (list/find/save/delete),
    # scoped to ONE owner and ONE index (storage_id). The FilterForm only reads
    # (list/find); save/delete are used by Bali::SavedViewsController. "Team-shared views"
    # (phase 2) is ANOTHER class with this same contract — the FilterForm never notices.
    class Store
      def initialize(owner:, storage_id:)
        @owner = owner
        @storage_id = storage_id
      end

      def list = scope.order(:name).to_a

      def find(id) = scope.find_by(id: id)

      # Upsert by name: saving "Míos" twice updates the view, it does not duplicate. The
      # rescue covers the double-click race: the second insert loses against the unique
      # index and the retry finds the row just created — the promised upsert, with no 500.
      def save(name:, payload:)
        view = scope.find_or_initialize_by(name: name)
        view.update!(payload: payload)
        view
      rescue ActiveRecord::RecordNotUnique
        view = scope.find_by!(name: name)
        view.update!(payload: payload)
        view
      end

      def delete(id) = scope.find_by(id: id)&.destroy!

      private

      def scope = SavedView.where(owner: @owner, storage_id: @storage_id)
    end
  end
end
