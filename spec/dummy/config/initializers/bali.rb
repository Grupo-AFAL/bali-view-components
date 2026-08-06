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
