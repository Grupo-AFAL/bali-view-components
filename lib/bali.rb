# frozen_string_literal: true

require "bali/ransack_param_name"
require "bali/search_config"
require "bali/filter_form"
require "bali/form_builder/html_utils"
require "bali/form_builder/shared_utils"
require "bali/form_builder/shared_date_utils"
require "bali/layout_concern"
require "bali/types/time_value"
require "bali/types/month_value"
require "bali/types/date_range_value"
require "bali/utils"
require "bali/html_element_helper"
require "bali/path_helper"
require "bali/form_helper"
require "bali/auto_submit_select_helper"
require "bali/icon_tag_helper"
require "bali/time_periods/select_options"

# Core concerns (used by components/form builder)
require "bali/concerns/date_range_attribute"

# Non-UI concerns (SoftDelete, GlobalIdAccessors, etc.) are opt-in.
# See lib/bali/extras.rb

# Form builder field modules
require "bali/form_builder/boolean_fields"
require "bali/form_builder/coordinates_polygon_fields"
require "bali/form_builder/currency_fields"
require "bali/form_builder/date_fields"
require "bali/form_builder/datetime_fields"
require "bali/form_builder/direct_upload_fields"
require "bali/form_builder/dynamic_fields"
require "bali/form_builder/email_fields"
require "bali/form_builder/error_summary_fields"
require "bali/form_builder/file_fields"
require "bali/form_builder/number_fields"
require "bali/form_builder/numeric_fields"
require "bali/form_builder/password_fields"
require "bali/form_builder/percentage_fields"
require "bali/form_builder/radio_fields"
require "bali/form_builder/range_fields"
require "bali/form_builder/recurrent_event_rule_fields"
require "bali/form_builder/rich_text_area_fields"
require "bali/form_builder/rich_text_fields"
require "bali/form_builder/search_fields"
require "bali/form_builder/select_fields"
require "bali/form_builder/slim_select_fields"
require "bali/form_builder/step_number_fields"
require "bali/form_builder/submit_fields"
require "bali/form_builder/switch_fields"
require "bali/form_builder/text_area_fields"
require "bali/form_builder/text_fields"
require "bali/form_builder/time_fields"
require "bali/form_builder/time_period_fields"
require "bali/form_builder/time_zone_select_fields"
require "bali/form_builder/url_fields"

# The v2 spellings, kept for one cycle. Removed in 4.0.
require "bali/form_builder/deprecated_names"

# Commands
require "bali/commands/csv_export"
require "bali/commands/xlsx_export"

require "bali/form_builder"

require "bali/version"
require "bali/engine"

module Bali
  mattr_accessor :native_app, default: false
  mattr_accessor :custom_icons, default: {}

  # Google Maps JavaScript API key, read by LocationsMap and by the form
  # builder's coordinates polygon field. Both used to call
  # `ENV.fetch("GOOGLE_MAPS_KEY")` on their own, which made the environment the
  # only place the key could come from — an application that keeps credentials
  # in `Rails.application.credentials` or in a secrets manager had to export an
  # environment variable just to satisfy this gem.
  #
  # The environment variable is still read, so nothing an app already does
  # stops working, but it is now the fallback rather than the source: an
  # explicit `Bali.google_maps_key = ...` wins.
  mattr_writer :google_maps_key, default: nil

  # Resolved per call, not memoised: `config/initializers` runs before an
  # application's own credential loading in more setups than not, and a value
  # frozen at boot would be the empty string forever in every one of them.
  def self.google_maps_key
    @@google_maps_key.presence || ENV["GOOGLE_MAPS_KEY"].presence
  end

  # Rich Text Editor configuration
  # Set to true to enable the Rich Text Editor component (requires TipTap dependencies)
  mattr_accessor :rich_text_editor_enabled, default: false

  # Block Editor configuration
  # Set to true to enable the Block Editor component (requires @blocknote/core)
  mattr_accessor :block_editor_enabled, default: false

  # Whether Block Editor code blocks get syntax highlighting. This is an
  # installation-level decision, not a per-field one: it depends on whether the
  # app installed `shiki`, which is optional and heavy (it ships every grammar —
  # turning this off took one real app's editor bundle from 14.3 MB to 4.0 MB).
  # With no shiki installed and this left on, inserting a code block logs an
  # error and renders unhighlighted. A component can still override per call.
  mattr_accessor :block_editor_syntax_highlighting, default: true

  # Block Editor upload configuration
  # Authorization lambda: receives the controller instance, must return truthy to allow upload.
  # Example: ->(controller) { controller.current_user.present? }
  mattr_accessor :block_editor_upload_authorize, default: nil

  # Custom upload handler lambda: receives (uploaded_file, controller), must return a URL string.
  # When nil, defaults to Active Storage (creates unattached blob).
  # Note: Default Active Storage handler creates unattached blobs. Configure a purge job
  # (e.g., ActiveStorage::Blob.unattached.where(created_at: ..2.days.ago).find_each(&:purge_later))
  # or use a custom handler for production workloads.
  # Example: ->(file, controller) { MyUploader.upload(file) }
  mattr_accessor :block_editor_upload_handler, default: nil

  # Allowed upload content types (array of MIME type strings).
  # Default includes images, PDFs, text, Office documents, and zip files.
  # See BlockEditorUploadsController::ALLOWED_CONTENT_TYPES for the full list.
  mattr_accessor :block_editor_allowed_upload_types, default: nil

  # Maximum upload file size in bytes. When nil the controller's own default
  # applies, which is 50.megabytes (BlockEditorUploadsController::MAX_FILE_SIZE).
  mattr_accessor :block_editor_max_upload_size, default: nil

  # Explicit upload URL path. When set, the component uses this instead of
  # auto-resolving from engine routes. Useful if you don't mount the engine.
  # Example: '/api/block_editor/uploads'
  mattr_accessor :block_editor_upload_url, default: nil

  # Comentarios del Block Editor (#706) — storage default de threads/comentarios/
  # reacciones (tablas `bali_block_editor_*`, instaladas con
  # `bin/rails bali:install:migrations`). Los tres callables de abajo son TODA la
  # configuración: sin ellos el engine responde 404 a cualquier petición.
  #
  # A qué modelos del host se les puede colgar un thread. Hash
  # `"Document" => Document` (usa `.find_by(id:)`) o `"Document" => ->(id) { ... }`
  # para scopear a mano. La clave es lo que guarda `commentable_type`, o sea
  # `record.class.polymorphic_name`.
  #
  # El default VACÍO es la postura de seguridad: montar el engine no habilita
  # comentarios en nada, y el tipo jamás se resuelve por `constantize`.
  # Example: Bali.block_editor_commentables = { "Document" => Document }
  mattr_accessor :block_editor_commentables, default: {}

  # Identidad del autor: callable evaluado con el controller, devuelve el **string**
  # del userId (el contrato del JS es string; el nombre a mostrar lo resuelve el
  # cliente con `comments[:users]`/`users_url`). Mismo aviso que saved_views: el
  # controller del engine no hereda el del host — ver docs/guides/engines.md.
  #
  # OJO: `RESTThreadStore` manda un header `X-User-Id`, y el engine lo IGNORA a
  # propósito. Es informativo; confiar en él dejaría comentar como cualquiera.
  # Example: ->(controller) { controller.current_member&.id&.to_s }
  mattr_accessor :block_editor_comments_user,
                 default: ->(controller) { controller.try(:current_user)&.id&.to_s }

  # Gate de acceso general: callable (controller, user_id, commentable) — truthy
  # permite, falsy responde 403. Es el permiso de ENTRADA; las reglas por acción
  # (solo el autor edita su comentario, solo el autor del primer comentario borra el
  # thread) están cableadas en los controllers replicando a `DefaultThreadStoreAuth`,
  # que es lo que la UI ya promete.
  # Example: ->(controller, user_id, commentable) { commentable.readable_by?(user_id) }
  mattr_accessor :block_editor_comments_authorize,
                 default: ->(_controller, user_id, _commentable) { user_id.present? }

  # Saved views (B2) — storage default que trae el engine (tabla `bali_saved_views`,
  # instalada con `bin/rails bali:install:migrations`).
  #
  # Dueño de las vistas: callable evaluado con el controller de la request. OJO: el
  # controller del ENGINE no hereda el ApplicationController del host, así que un
  # `current_user` que viva en un concern del host no existe ahí solo — o el host se lo
  # enseña (p.ej. `Bali::SavedViewsController.include MiAuthConcern` en un to_prepare,
  # skipeando los before_action del concern) o configura este callable.
  # Example: ->(controller) { controller.current_member }
  mattr_accessor :saved_views_owner, default: ->(controller) { controller.try(:current_user) }

  # Autorización de Bali::SavedViewsController: callable (controller, owner) — truthy
  # permite, falsy responde 403. El default exige owner presente; una app puede endurecerlo
  # (p.ej. Pundit) porque los hooks del ApplicationController del HOST no aplican en el
  # controller del engine.
  # Example: ->(controller, owner) { owner&.can?("tdflow.access") }
  mattr_accessor :saved_views_authorize, default: ->(_controller, owner) { owner.present? }

  # Concerns the host injects into every controller of this engine (#710).
  #
  # `isolate_namespace` means `Bali::ApplicationController` inherits from
  # `ActionController::Base`, NOT from the host's `ApplicationController` — so the
  # host's authentication (`current_user`, session helpers, `Current`) does not
  # exist inside the engine's controllers unless the host teaches it. Every module
  # in this array is included into `Bali::ApplicationController` on each
  # `to_prepare` (idempotent, and it survives code reloads in development), which
  # covers saved views, block editor uploads and every controller the engine grows
  # later, all at once.
  #
  # Keep the injected concern PASSIVE: it should teach context (`current_user`),
  # not enforce access — an active `authenticate_user!` before_action would
  # redirect to login and shadow the engine's own 403s. The real gate stays in the
  # `Bali.*_authorize` lambdas. Full guide, including the bali-auth recipe:
  # docs/guides/engines.md.
  # Example: Bali.engine_controller_concerns = [EngineAuthentication]
  mattr_accessor :engine_controller_concerns, default: []

  # Every deprecation this gem emits goes through here. The engine registers it
  # as `app.deprecators[:bali]`, so a host silences, logs or raises Bali's
  # warnings with the same `config.active_support.deprecation` it already uses
  # for Rails' own — and `Bali.deprecator.silence { }` scopes an exception.
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("4.0", "Bali")
  end

  def self.add_icon(name, svg_str)
    custom_icons[name.to_s] = svg_str
  end

  def self.config
    yield(self)
  end
end
