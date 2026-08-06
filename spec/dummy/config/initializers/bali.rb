# frozen_string_literal: true

Bali.config do |config|
  # Rich Text Editor is disabled by default to avoid loading TipTap dependencies
  # Set ENABLE_RICH_TEXT_EDITOR=1 to enable for testing
  config.rich_text_editor_enabled = ENV['ENABLE_RICH_TEXT_EDITOR'].present?

  # Block Editor is enabled in the dummy app for demonstration
  # In production apps, set to true only if @blocknote/core is installed
  config.block_editor_enabled = true

  # `Bali::SavedViewsController` hereda `Bali::ApplicationController`, no el del dummy: el
  # `current_user` del host no existe ahí y el default (`controller.try(:current_user)`)
  # devuelve nil, así que sin esto guardar una vista responde 403.
  config.saved_views_owner = ->(_controller) { User.demo }

  # #708 — los tipos que el `#` del BlockEditor puede referenciar. UNA declaración por tipo:
  # de aquí salen el buscador, la resolución de los chips y el `references_config` que el
  # componente le pasa al JS (el `display:`), que antes eran tres declaraciones paralelas.
  #
  # `url:` usa los url_helpers globales a propósito: el resolver corre en el controller del
  # engine, fuera de una vista, donde `main_app` no existe.
  routes = Rails.application.routes.url_helpers

  config.entity_reference_types = {
    'Document' => {
      search_scope: -> { Document.where.not(status: :archived) },
      # A propósito MÁS AMPLIO que el de búsqueda: un documento archivado ya no se ofrece
      # en el autocompletado, pero una referencia vieja tiene que seguir resolviéndose para
      # pintarse como chip roto en vez de desaparecer del texto.
      lookup_scope: -> { Document.all },
      search_fields: %i[title],
      display_field: :title,
      url: ->(document) { routes.document_path(document) },
      unreachable?: ->(document) { document.nil? || document.archived? },
      extra_payload: ->(document) { { entityTypeLabel: document.status.titleize } },
      display: { icon: '▧', label: 'Document', color: 'success' }
    },
    'Project' => {
      search_scope: -> { Project.all },
      lookup_scope: -> { Project.all },
      search_fields: %i[name],
      display_field: :name,
      url: ->(project) { routes.admin_project_path(project) },
      display: { icon: '◈', label: 'Project', color: 'accent' }
    },
    'Task' => {
      search_scope: -> { Task.where.not(status: :done) },
      lookup_scope: -> { Task.all },
      search_fields: %i[title],
      display_field: :title,
      url: ->(task) { routes.admin_project_path(task.project) },
      unreachable?: ->(task) { task.nil? || task.done? },
      display: { icon: '☐', label: 'Task', color: 'info' }
    }
  }

  # El default del engine DENIEGA (los endpoints listan registros del host). El dummy no
  # autentica, así que abre; una app real exigiría sesión aquí y scopearía por tipo con
  # `permission_scope:`.
  config.entity_references_authorize = ->(_controller) { true }

  # Historial de contenido (#707). La whitelist es lo que hace que `Document` sea legible
  # por `Bali::ContentVersionsController`: sin esta línea el engine responde 404 a
  # cualquier `record_type`, que es el default deliberado.
  config.content_versionables = {
    'Document' => ->(_controller, id) { Document.find_by(id: id) }
  }

  # El dummy no autentica, así que aquí solo se pinta el gate: un host real decide con su
  # `current_user` (y puede permitir leer a todos y restaurar solo a algunos, mirando
  # `action`).
  config.content_versions_authorize = ->(_controller, record, _action) { record.present? }

  # El default resuelve `controller.current_user`, que en el engine no existe: sin esto la
  # versión que crea el restore se firmaría "Unknown".
  config.content_versions_author = ->(_controller) { [User.demo, User.demo.name] }
end
