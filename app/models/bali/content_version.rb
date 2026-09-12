# frozen_string_literal: true

module Bali
  # #707 — una versión del contenido de CUALQUIER modelo del host (`record` polimórfico).
  # No se crea a mano: el modelo versionado la produce a través de `Bali::ContentVersionable`
  # (`create_version!` / `create_or_coalesce_version!`), que es quien conoce el atributo
  # versionado y quien numera.
  #
  # `author` es opcional y `author_name` obligatorio a propósito: el JSON que lee
  # `document_editor/index.js` solo sirve `author_name`, así que un host sin modelo de
  # usuario deja el FK en nil sin perder nada de la UI.
  class ContentVersion < ApplicationRecord
    belongs_to :record, polymorphic: true
    belongs_to :author, polymorphic: true, optional: true

    # ActiveStorage sigue siendo opcional en el engine: un host que no lo carga no tiene
    # `has_one_attached` definido y el modelo entero fallaría al autoloadearse. Sin
    # validación de presencia — la columna existe para el caso "versión de un archivo"
    # (el content_kind de gc), no para exigirla.
    has_one_attached :file if respond_to?(:has_one_attached)

    # El mismo límite que la columna. Estar en los dos lados es deliberado: la validación
    # convierte un resumen larguísimo en un error de modelo que el host puede mostrar, y la
    # columna lo sostiene aunque alguien escriba por fuera del modelo.
    SUMMARY_MAX_LENGTH = 255

    validates :version_number, presence: true,
                               uniqueness: { scope: %i[record_type record_id] }
    validates :author_name, presence: true
    validates :summary, length: { maximum: SUMMARY_MAX_LENGTH }, allow_nil: true

    # `reorder`, no `order`: la asociación `content_versions` ya ordena ascendente y un
    # `order` encadenado se APILA detrás, así que la primera cláusula seguiría ganando y
    # esto devolvería la versión más vieja — que es justo con la que compara el coalescing.
    scope :newest_first, -> { reorder(version_number: :desc) }

    # El mismo autor de dos versiones consecutivas: por FK cuando alguno de los dos lados
    # lo tiene, por nombre cuando el host no tiene modelo de usuario. Lo usa el coalescing.
    # Lee `author_id`, no `author`, para no cargar el registro solo para compararlo.
    def same_author?(other_author, other_author_name)
      return author_name == other_author_name if author_id.nil? && other_author.nil?

      other_author.present? &&
        author_type == other_author.class.polymorphic_name &&
        author_id == other_author.id
    end
  end
end
