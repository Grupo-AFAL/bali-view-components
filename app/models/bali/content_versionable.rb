# frozen_string_literal: true

module Bali
  # #707 — historial de contenido para un modelo del host:
  #
  #   class Document < ApplicationRecord
  #     include Bali::ContentVersionable
  #     content_versionable attribute: :content, coalesce_window: 5.minutes
  #   end
  #
  # El macro es opcional: `include` solo ya aplica los defaults (`:content`, 5 minutos).
  #
  # La ventana de coalescing es un parámetro del MODELO, no config global: cuánto dura una
  # "sesión de edición" depende de qué se está editando, no de la app.
  #
  # OJO con el reparto de responsabilidades: el engine NO crea versiones en el autosave. El
  # PATCH del autosave va a la URL del host (`document_editor/index.js`), así que es el
  # host quien llama `create_or_coalesce_version!` en su `update`. El engine solo lee
  # (index/show) y restaura — ver `Bali::ContentVersionsController`.
  module ContentVersionable
    extend ActiveSupport::Concern

    DEFAULT_COALESCE_WINDOW = 5.minutes

    included do
      class_attribute :content_version_attribute, instance_writer: false, default: :content
      class_attribute :content_version_coalesce_window, instance_writer: false,
                                                        default: DEFAULT_COALESCE_WINDOW

      has_many :content_versions, -> { order(version_number: :asc) },
               class_name: "Bali::ContentVersion", as: :record, dependent: :destroy
    end

    class_methods do
      # Solo configura: la asociación se declara en el `included` para que llamar el macro
      # dos veces (o no llamarlo) no registre el `dependent: :destroy` por duplicado.
      def content_versionable(attribute: :content, coalesce_window: DEFAULT_COALESCE_WINDOW)
        self.content_version_attribute = attribute.to_sym
        self.content_version_coalesce_window = coalesce_window
      end
    end

    def current_content_version_number
      content_versions.maximum(:version_number) || 0
    end

    # Bajo el mismo lock que el coalescing, y por la misma razón: entre leer el número más
    # alto y escribir el siguiente cabe otra escritura. Sin lock falla cerrado (el índice
    # único rechaza el duplicado), pero este es el método que los hosts llaman desde su
    # `create`/`update`, así que el modo de fallo era un 500 en una carrera.
    #
    # Efecto secundario, y es el deseable: Rails se niega a lockear un registro con cambios
    # sin guardar, así que versionar en medio de una edición sin persistir ahora falla
    # ruidosamente en vez de guardar una versión que afirma un contenido que la base nunca
    # vio. Hay que llamar esto DESPUÉS del `save`, que es lo que ya hacían el dummy y
    # gobierno-corporativo. `create_or_coalesce_version!` se comportaba así desde el
    # principio; ahora los dos coinciden.
    def create_version!(author_name:, author: nil, summary: nil, metadata: nil)
      with_lock do
        content_versions.create!(
          content: versioned_content,
          version_number: current_content_version_number + 1,
          author: author,
          author_name: author_name,
          summary: summary,
          metadata: metadata || {}
        )
      end
    end

    # Una ráfaga de autosaves del mismo autor produce UNA versión, no doce: dentro de la
    # ventana se actualiza la última en vez de crear otra.
    #
    # `with_lock` no es decoración — dos autosaves concurrentes leerían la misma "última
    # versión" y crearían dos filas con el mismo `version_number`, que el índice único
    # rechaza. Es el patrón de gobierno-corporativo; la implementación del dummy sin lock
    # era el bug, no el patrón.
    def create_or_coalesce_version!(author_name:, author: nil, summary: nil, metadata: nil)
      with_lock do
        last = content_versions.newest_first.first

        if last && last.same_author?(author, author_name) &&
           last.created_at > content_version_coalesce_window.ago
          # `summary` solo pisa cuando viene: el autosave no manda ninguno, y asignar nil
          # borraría en silencio el nombre que la versión ya tenía ("Initial draft").
          attributes = { content: versioned_content }
          attributes[:summary] = summary if summary
          attributes[:metadata] = metadata if metadata
          last.update!(attributes)
          last
        else
          create_version!(author_name: author_name, author: author,
                          summary: summary, metadata: metadata)
        end
      end
    end

    def content_at_version(version_number)
      content_versions.find_by(version_number: version_number)&.content
    end

    # Restaurar deja rastro: el contenido vuelve y nace una versión nueva que dice de dónde
    # vino. No se guarda una versión extra "antes de restaurar" porque el autosave del host
    # ya mantiene la última versión al día con el contenido vigente — la cabeza del
    # historial ES el estado previo.
    #
    # El `summary` default se traduce al restaurar y se GUARDA como texto: es un dato
    # histórico, no una vista. Un host que sirva varios idiomas y prefiera resolverlo al
    # render pasa el suyo.
    def restore_content_version!(version, author_name:, author: nil, summary: nil)
      # Se re-scopea SIEMPRE, también cuando llega un objeto: aceptarlo tal cual dejaba
      # copiar el contenido de la versión de CUALQUIER otro registro sobre este. El
      # controller ya buscaba dentro de `@record.content_versions`, pero esto es una API
      # pública del modelo y un host que traiga la versión de otro lado merecía un
      # RecordNotFound, no una restauración silenciosa de contenido ajeno.
      version = content_versions.find(version.is_a?(Bali::ContentVersion) ? version.id : version)

      with_lock do
        update!(content_version_attribute => version.content)
        create_version!(
          author_name: author_name,
          author: author,
          summary: summary || I18n.t("bali_view.content_versions.restored_from",
                                     number: version.version_number)
        )
      end
    end

    private

    def versioned_content
      public_send(content_version_attribute)
    end
  end
end
