# frozen_string_literal: true

Bali.config do |config|
  # Rich Text Editor is disabled by default to avoid loading TipTap dependencies
  # Set ENABLE_RICH_TEXT_EDITOR=1 to enable for testing
  config.rich_text_editor_enabled = ENV['ENABLE_RICH_TEXT_EDITOR'].present?

  # Block Editor is enabled in the dummy app for demonstration
  # In production apps, set to true only if @blocknote/core is installed
  config.block_editor_enabled = true

  # `Bali::SavedViewsController` inherits `Bali::ApplicationController`, not the dummy's:
  # the host's `current_user` does not exist there and the default
  # (`controller.try(:current_user)`) returns nil, so without this saving a view answers 403.
  config.saved_views_owner = ->(_controller) { User.demo }

  # Who the persisted filters belong to (#999): `Bali::Filterable#filter_form` evaluates
  # this against the controller and passes it as `context:`. The engine's default uses
  # `current_user&.id`, but the demo has ONE user — the identity that separates here is the
  # browser (see ApplicationController#filter_context).
  config.filter_context = ->(controller) { controller.send(:filter_context) }

  # #708 — the types the BlockEditor's `#` can reference. ONE declaration per type: the
  # search, the chip resolution and the `references_config` the component hands the JS (the
  # `display:`) all come from here, where they used to be three parallel declarations.
  #
  # `url:` uses the global url_helpers on purpose: the resolver runs in the engine's
  # controller, outside a view, where `main_app` does not exist.
  routes = Rails.application.routes.url_helpers

  config.entity_reference_types = {
    'Document' => {
      search_scope: -> { Document.where.not(status: :archived) },
      # WIDER than the search scope on purpose: an archived document is no longer offered
      # in autocomplete, but an old reference has to keep resolving so it paints as a broken
      # chip instead of vanishing from the text.
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

  # The engine's default DENIES (the endpoints list host records). The dummy does not
  # authenticate, so it opens up; a real app would demand a session here and scope per type
  # with `permission_scope:`.
  config.entity_references_authorize = ->(_controller) { true }

  # Content history (#707). The whitelist is what makes `Document` readable by
  # `Bali::ContentVersionsController`: without this line the engine answers 404 to any
  # `record_type`, which is the deliberate default.
  config.content_versionables = {
    'Document' => ->(_controller, id) { Document.find_by(id: id) }
  }

  # The dummy does not authenticate, so the gate here is only for show: a real host decides
  # with its `current_user` (and can let everyone read and only a few restore, by looking at
  # `action`).
  config.content_versions_authorize = ->(_controller, record, _action) { record.present? }

  # The default resolves `controller.current_user`, which does not exist in the engine:
  # without this the version the restore creates would be signed "Unknown".
  config.content_versions_author = ->(_controller) { [User.demo, User.demo.name] }

  # #706 — which dummy records can carry comment threads. The default is
  # `{}`, that is 404 for everything: mounting the engine enables comments on nothing.
  #
  # The key is what gets stored in `commentable_type` (`Document.polymorphic_name`).
  # The value goes as a STRING and not as the class: a class stored here holds on to the
  # copy Zeitwerk discards on the next reload, and Lookbook reloads all day long.
  config.block_editor_commentables = { 'Document' => 'Document' }

  # Same reason as `saved_views_owner`: the engine's controller does not inherit the
  # dummy's. The user id is a STRING and has to be one of those the views declare in
  # `comments[:users]` (DocumentsController::DEMO_USERS), or the editor only knows how to
  # label it "User <id>".
  config.block_editor_comments_user = ->(_controller) { 'user-1' }
end
