# frozen_string_literal: true

module Bali
  # B2 — endpoints of the saved views' default storage (the UI is
  # Bali::DataTable::SavedViews; the index consumes them through Bali::SavedView::Store).
  # No index/show: the FilterForm lists them.
  #
  # Authorization: this controller does NOT inherit the host ApplicationController's hooks
  # (an app-wide `verify_pundit` does not apply here), so the gate lives inside:
  # `Bali.saved_views_owner` resolves the owner and `Bali.saved_views_authorize` decides —
  # the default requires the owner to be present (no session → 403). EVERYTHING else is
  # the owner's: create scopes the store by the owner and update/destroy look ONLY among
  # the user's own views (someone else's view is a 404, not a 403 confirming it exists).
  class SavedViewsController < ApplicationController
    before_action :authorize_saved_views!

    def create
      store.save(name: params.require(:name), payload: params[:payload])
      redirect_back fallback_location: fallback_path, notice: t("bali_view.saved_views.saved")
    rescue ActiveRecord::RecordInvalid => e
      redirect_back fallback_location: fallback_path, alert: e.record.errors.full_messages.to_sentence
    end

    # Serves TWO operations: renaming (sends `name`) and updating the saved configuration
    # (sends `payload`). ONLY what came in is assigned: always assigning both would make
    # renaming EMPTY the payload —`SavedView#payload=` slices, so a nil silently wipes the
    # configuration— and make updating overwrite the name with a blank.
    def update
      view = own_views.find(params[:id])
      attributes = params.permit(:name, :payload).to_h.symbolize_keys.compact
      raise ActionController::ParameterMissing, :name if attributes.empty?

      view.update!(attributes)
      redirect_back fallback_location: fallback_path,
                    notice: t("bali_view.saved_views.#{attributes.key?(:payload) ? 'updated' : 'renamed'}")
    rescue ActiveRecord::RecordInvalid => e
      redirect_back fallback_location: fallback_path, alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      view = own_views.find(params[:id])
      view.destroy!
      redirect_back fallback_location: fallback_path, notice: t("bali_view.saved_views.deleted")
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

    # Bali's drawer posts with redirect_back, so the referer almost always exists; the
    # engine does not know the host's index pages, hence the neutral fallback.
    def fallback_path = main_app.try(:root_path) || "/"
  end
end
