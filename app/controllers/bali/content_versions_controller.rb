# frozen_string_literal: true

module Bali
  # #707 — los tres endpoints que el panel de historial del DocumentEditor consume:
  # index (lista), show (contenido de una versión para el preview) y restore.
  #
  # El registro versionado NO viaja en la ruta: llega por query string
  # (`?record_type=Document&record_id=7`), porque el engine no conoce los modelos del host
  # y no puede montar una ruta anidada por cada uno. El restore además manda `version_id`
  # en el body, como ya hace `document_editor/index.js`.
  #
  # Autorización, en dos capas y ambas default-deny:
  #   1. `Bali.content_versionables` es una whitelist tipo→resolver. Vacía por default, así
  #      que sin configuración TODO es 404. Sin ella, `record_type` sería un
  #      `constantize` sobre parámetros del usuario: cualquier modelo de la app legible por
  #      HTTP.
  #   2. `Bali.content_versions_authorize` decide (default falsy → 403). Vive aquí y no en
  #      un before_action del host porque este controller hereda `Bali::ApplicationController`,
  #      no el del host — ver docs/guides/engines.md.
  class ContentVersionsController < ApplicationController
    before_action :set_record
    before_action :authorize_content_versions!

    # El `select` no es microoptimización: `content` es el documento entero y el index NO lo
    # sirve. Sin recortar columnas, un registro con 200 versiones leía 31.5 MB de la base
    # para responder un body de 22.6 KB, y tardaba 4.1× más. El panel de historial se abre
    # en cada edición, así que ese costo se paga todo el tiempo.
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

    # Cada versión lleva su propia `url` (:369 de document_editor/index.js la prefiere sobre
    # armarla por interpolación): el engine puede estar montado en cualquier path y el JS no
    # tiene por qué saberlo.
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

      # Whitelistear un modelo que nunca incluyó el concern es un error de configuración del
      # host, y respondía 500 (NoMethodError sobre `content_versions`). No hay historial que
      # servir, así que es un 404 como cualquier otro registro sin versiones: el mismo
      # default-deny, sin regalar un stack trace.
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
