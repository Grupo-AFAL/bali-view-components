# frozen_string_literal: true

module Bali
  # B2 — endpoints del storage default de las vistas guardadas (la UI es
  # Bali::DataTable::SavedViews; el listado las consume vía Bali::SavedView::Store).
  # Sin index/show: las lista el FilterForm.
  #
  # Autorización: este controller NO hereda los hooks del ApplicationController del host
  # (un `verify_pundit` app-wide no aplica aquí), así que el gate vive adentro:
  # `Bali.saved_views_owner` resuelve al dueño y `Bali.saved_views_authorize` decide —
  # el default exige owner presente (sin sesión → 403). TODO lo demás es del dueño:
  # create scopea el store por el owner y update/destroy buscan SOLO entre las vistas
  # propias (una vista ajena es un 404, no un 403 que confirme que existe).
  class SavedViewsController < ApplicationController
    before_action :authorize_saved_views!

    def create
      store.save(name: params.require(:name), payload: params[:payload])
      redirect_back fallback_location: fallback_path, notice: t("bali.saved_views.saved")
    rescue ActiveRecord::RecordInvalid => e
      redirect_back fallback_location: fallback_path, alert: e.record.errors.full_messages.to_sentence
    end

    def update
      view = own_views.find(params[:id])
      view.update!(name: params.require(:name))
      redirect_back fallback_location: fallback_path, notice: t("bali.saved_views.renamed")
    rescue ActiveRecord::RecordInvalid => e
      redirect_back fallback_location: fallback_path, alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      view = own_views.find(params[:id])
      view.destroy!
      redirect_back fallback_location: fallback_path, notice: t("bali.saved_views.deleted")
    end

    private

    def owner
      return @owner if defined?(@owner)

      @owner = Bali.saved_views_owner.call(self)
    end

    def authorize_saved_views!
      head :forbidden unless Bali.saved_views_authorize.call(self, owner)
    end

    def own_views = SavedView.where(owner: owner)

    def store
      SavedView::Store.new(owner: owner, storage_id: params.require(:storage_id))
    end

    # El drawer de Bali postea con redirect_back, así que el referer casi siempre existe;
    # el engine no conoce los listados del host, de ahí el fallback neutro.
    def fallback_path = main_app.try(:root_path) || "/"
  end
end
