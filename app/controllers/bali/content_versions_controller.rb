# frozen_string_literal: true

module Bali
  # #707 — the three endpoints the DocumentEditor's history panel consumes:
  # index (the list), show (the content of one version, for the preview) and restore.
  #
  # The versioned record does NOT travel in the route: it arrives in the query string
  # (`?record_type=Document&record_id=7`), because the engine does not know the host's
  # models and cannot mount a nested route for each one. Restore also sends `version_id`
  # in the body, as `document_editor/index.js` already does.
  #
  # Authorization, in two layers and both default-deny:
  #   1. `Bali.content_versionables` is a type→resolver whitelist. Empty by default, so
  #      with no configuration EVERYTHING is a 404. Without it, `record_type` would be a
  #      `constantize` over user parameters: any model in the app readable over HTTP.
  #   2. `Bali.content_versions_authorize` decides (falsy by default → 403). It lives here and
  #      not in a host before_action because this controller inherits `Bali::ApplicationController`,
  #      not the host's — see docs/guides/engines.md.
  class ContentVersionsController < ApplicationController
    before_action :set_record
    before_action :authorize_content_versions!

    # The `select` is not a micro-optimization: `content` is the whole document and index
    # does NOT serve it. Without trimming columns, a record with 200 versions read 31.5 MB
    # from the database to answer a 22.6 KB body, and took 4.1× longer. The history panel
    # opens on every edit, so that cost is paid all the time.
    INDEX_COLUMNS = %i[id version_number author_name summary created_at].freeze

    def index
      versions = @record.content_versions.newest_first.select(*INDEX_COLUMNS)
      render json: versions.map { |version| version_json(version) }
    end

    def show
      version = @record.content_versions.find(params[:id])
      render json: version_json(version).merge(content: version.content,
                                               metadata: version.metadata)
    end

    def restore
      version = @record.content_versions.find(params.require(:version_id))
      author, author_name = Bali.content_versions_author.call(self)
      @record.restore_content_version!(version, author: author, author_name: author_name)

      render json: { status: "ok", version_number: @record.current_content_version_number }
    end

    private

    # Each version carries its own `url` (:369 of document_editor/index.js prefers it over
    # building it by interpolation): the engine can be mounted at any path and the JS has no
    # way to know it.
    def version_json(version)
      {
        id: version.id,
        version_number: version.version_number,
        author_name: version.author_name,
        summary: version.summary,
        created_at: version.created_at.iso8601,
        url: content_version_path(version, record_type: record_type, record_id: record_id)
      }
    end

    def set_record
      resolver = Bali.content_versionables[record_type]
      return head :not_found if resolver.blank?

      @record = resolver.call(self, record_id)
      return head :not_found if @record.blank?

      # Whitelisting a model that never included the concern is a host configuration
      # mistake, and it answered 500 (NoMethodError on `content_versions`). There is no
      # history to serve, so it is a 404 like any other record with no versions: the same
      # default-deny, without handing out a stack trace.
      head :not_found unless @record.is_a?(Bali::ContentVersionable)
    end

    def authorize_content_versions!
      return if Bali.content_versions_authorize.call(self, @record, action_name)

      head :forbidden
    end

    def record_type = params[:record_type].to_s

    def record_id = params[:record_id].to_s
  end
end
