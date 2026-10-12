# frozen_string_literal: true

module Bali
  # #721 — archive and reopen a host record. The record arrives in the query string
  # (`?record_type=Document&record_id=7`) and two default-deny layers stand before every action,
  # as in Bali::ContentVersionsController: `Bali.archivables` (404) and
  # `Bali.archivals_authorize` (403). A track rule reads `@record` and, after `create`,
  # `@archival`; renaming either silences it.
  class ArchivalsController < ApplicationController
    # The drawer inserts this body. Without the line Rails renders `layouts/bali/application`,
    # which links a `bali/application` stylesheet that no host ships.
    layout false

    before_action :set_record
    before_action :authorize_archivals!
    before_action :set_successors, only: %i[new create]

    def new; end

    def create
      @archival = @record.archive!(by: actor, **archival_params)
      redirect_to return_path, status: :see_other
    rescue ActiveRecord::RecordInvalid => error
      @archival = error.record
      render :new, status: :unprocessable_content
    rescue Bali::Archivable::AlreadyArchived
      redirect_to return_path, status: :see_other
    end

    def unarchive
      @record.unarchive!(by: actor)
      redirect_to return_path, status: :see_other
    rescue Bali::Archivable::NotReversible
      head :not_found
    rescue Bali::Archivable::NotArchived
      redirect_to return_path, status: :see_other
    end

    private

    def set_record
      @record = Bali.archivables[params[:record_type].to_s]&.call(self, params[:record_id].to_s)
      head :not_found unless @record.is_a?(Bali::Archivable)
    end

    def authorize_archivals!
      head :forbidden unless Bali.archivals_authorize.call(self, @record, action_name)
    end

    def set_successors
      @successors = Bali.archivals_successors.call(self, @record)
    end

    def actor = Bali.archivals_actor.call(self)

    # The successor is looked up among the candidates, never by a type the request names.
    def archival_params
      permitted = params.expect(archival: %i[reason note successor_id])
      { reason: permitted[:reason].presence, note: permitted[:note].presence,
        successor: @successors&.find_by(id: permitted[:successor_id]) }
    end

    # Rails' own guard against open redirects: a path or URL of this host, else nil.
    def return_to = url_from(params[:return_to])
    helper_method :return_to

    def return_path = return_to || main_app.polymorphic_path(@record)
  end
end
