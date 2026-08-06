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

  # #706 — qué registros del dummy pueden llevar hilos de comentarios. El default es
  # `{}`, o sea 404 para todo: montar el engine no habilita comentarios en nada.
  #
  # La clave es lo que se guarda en `commentable_type` (`Document.polymorphic_name`).
  # El valor va como STRING y no como la clase: una clase guardada acá se queda con la
  # copia que Zeitwerk descarta en el próximo reload, y Lookbook recarga todo el día.
  config.block_editor_commentables = { 'Document' => 'Document' }

  # Misma razón que `saved_views_owner`: el controller del engine no hereda el del
  # dummy. El id del usuario es un STRING y tiene que ser uno de los que las vistas
  # declaran en `comments[:users]` (DocumentsController::DEMO_USERS), o el editor solo
  # sabe rotular "User <id>".
  config.block_editor_comments_user = ->(_controller) { 'user-1' }
end
