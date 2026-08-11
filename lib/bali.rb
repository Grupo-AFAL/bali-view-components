# frozen_string_literal: true

require "bali/ransack_param_name"
require "bali/date_range_presets"
require "bali/search_config"
require "bali/filter_form"
require "bali/form_builder/html_utils"
require "bali/form_builder/shared_utils"
require "bali/form_builder/shared_date_utils"
require "bali/layout_concern"
require "bali/filterable"
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
  # Default-deny since v3.1: while this is nil the uploads endpoint returns 403 (and logs why),
  # matching the engine's other gates. Set `->(_) { true }` to keep it open on an internal app.
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
  # Un lambda de aridad 2 recibe el CONTROLLER primero (misma forma que
  # `content_versionables`), que es lo que permite scopear por usuario y responder
  # 404 a lo ajeno en vez del 403 del authorize (el par 403/404 es un oráculo).
  # Example: Bali.block_editor_commentables =
  #   { "Document" => ->(c, id) { c.current_user.documents.find_by(id: id) } }
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

  # Whose filters a listing persists (#999): `Bali::Filterable#filter_form`
  # evaluates this against the controller and passes the result as the form's
  # `context:`. Without a context the persistence cache_key is ONE for the
  # whole process and two users overwrite each other's restored filters — the
  # default keeps that from being the out-of-the-box behaviour in any app with
  # a `current_user`. Same shape as `saved_views_owner`; override for other
  # identities (an account, a visitor token), or set to `nil`/a nil-returning
  # lambda to opt out globally.
  # Example: Bali.filter_context = ->(controller) { controller.current_account&.id }
  mattr_accessor :filter_context, default: ->(controller) { controller.try(:current_user)&.id }

  # Autorización de Bali::SavedViewsController: callable (controller, owner) — truthy
  # permite, falsy responde 403. El default exige owner presente; una app puede endurecerlo
  # (p.ej. Pundit) porque los hooks del ApplicationController del HOST no aplican en el
  # controller del engine.
  # Example: ->(controller, owner) { owner&.can?("tdflow.access") }
  mattr_accessor :saved_views_authorize, default: ->(_controller, owner) { owner.present? }

  # Referencias de entidades (#708) — UNA declaración por tipo referenciable, que alimenta
  # las tres cosas que antes se declaraban por separado: el buscador del `#`, la resolución
  # de los chips y el `references_config` que el BlockEditor le pasa al JS.
  #
  # La clave es a la vez el `entityType` que viaja al navegador y el `referenceable_type`
  # que se guarda en `bali_entity_references`, así que es el nombre de la clase.
  #
  #   Bali.entity_reference_types = {
  #     "Document" => {
  #       search_scope:  -> { Document.published },      # lo que ofrece el autocompletado
  #       lookup_scope:  -> { Document.all },            # INCLUYE archivados: un chip roto
  #       search_fields: %i[title document_number],      #   se pinta, no desaparece
  #       display_field: :title,
  #       url:           ->(doc) { Rails.application.routes.url_helpers.document_path(doc) },
  #       unreachable?:  ->(doc) { doc.nil? || doc.archived? },
  #       extra_payload: ->(doc) { { entityCode: doc.number } },
  #       permission_scope: ->(controller, scope) { Pundit.policy_scope!(controller.current_user, scope) },
  #       display:       { icon: "▧", label: "Documento", color: "success" }
  #     }
  #   }
  #
  # `url:` es del host A PROPÓSITO: el engine no conoce las rutas de la app y el resolver
  # corre fuera de una vista, donde `main_app` no existe. Solo `search_scope`,
  # `lookup_scope`, `search_fields` y `display_field` son obligatorios. Guía completa de
  # adopción: docs/guides/engines.md.
  mattr_accessor :entity_reference_types, default: {}

  # Las claves se normalizan a String al asignar. Son a la vez el `entityType` del JSON y el
  # `referenceable_type` de la tabla, y el registry se lee desde los dos lados: declararlo con
  # símbolos dejaba al controller resolviendo TODO como roto (compara contra un String de
  # params) mientras el modelo lo veía TODO alcanzable, sin un error que lo delatara.
  def self.entity_reference_types=(types)
    @@entity_reference_types = types.to_h { |type, config| [ type.to_s, config ] } # rubocop:disable Style/ClassVars
  end

  # Autorización de Bali::EntityReferencesController: callable (controller) — truthy permite,
  # falsy responde 403. El default DENIEGA: los endpoints exponen nombres de registros del
  # host, así que hay que abrirlos a mano (y con `permission_scope:` por tipo para el resto).
  # Example: ->(controller) { controller.current_user.present? }
  mattr_accessor :entity_references_authorize, default: ->(_controller) { false }

  # El sub-hash `display:` del registry, listo para el `references_config` del BlockEditor.
  # El componente lo usa como default cuando el host no pasa `references_config:`, que es lo
  # que hace que declarar un tipo baste para que su chip salga con su icono y su color.
  def self.entity_references_config
    entity_reference_types.each_with_object({}) do |(type, config), out|
      display = config[:display]
      next if display.blank?

      out[type.to_s] = display.symbolize_keys.slice(:icon, :label, :color)
    end
  end

  # Alcanzabilidad de un referido según su tipo en el registry. Un tipo sin registrar cae al
  # default (presente = alcanzable), que es lo que quiere un panel que lista referencias
  # viejas de un tipo dado de baja.
  def self.entity_reference_unreachable?(type, record)
    gate = entity_reference_types.dig(type.to_s, :unreachable?)
    (gate || Bali::EntityReference::Resolver::DEFAULT_UNREACHABLE).call(record)
  end

  # Content versions (#707) — historial polimórfico del engine documental (tabla
  # `bali_content_versions`, instalada con `bin/rails bali:install:migrations`).
  #
  # Whitelist de modelos versionables que `Bali::ContentVersionsController` acepta por
  # HTTP: `{ "Document" => ->(controller, id) { ... } }`. La llave es el `record_type` que
  # viaja en el query string (el `polymorphic_name` del modelo) y el valor un callable que
  # devuelve el registro o nil. El default `{}` es DEFAULT-DENY: sin whitelist, cualquier
  # `record_type` responde 404 — la única forma de exponer un modelo es nombrarlo aquí.
  #
  # El resolver es el lugar del scoping: devolver solo lo que ese usuario puede ver
  # (`controller.current_user.documents.find_by(id: id)`) hace que lo ajeno sea un 404 en
  # vez de un 403 que confirme que existe.
  # Example: Bali.content_versionables = {
  #   "Document" => ->(controller, id) { controller.current_user.documents.find_by(id: id) }
  # }
  mattr_accessor :content_versionables, default: {}

  # Autorización de Bali::ContentVersionsController: callable (controller, record, action)
  # — truthy permite, falsy responde 403. El default NIEGA todo: leer el historial de un
  # modelo del host es una decisión del host, y los hooks de su ApplicationController no
  # aplican en el controller del engine. `action` es "index", "show" o "restore", así que
  # se puede dejar leer a todos y restaurar solo a algunos.
  # Example: ->(controller, record, action) { action == "restore" ? record.editable_by?(controller.current_user) : true }
  mattr_accessor :content_versions_authorize, default: ->(_controller, _record, _action) { false }

  # Autor de las versiones que CREA el engine (hoy solo la del restore): callable
  # (controller) que devuelve `[author, author_name]`. `author` es opcional —un host sin
  # modelo de usuario devuelve nil y solo nombra—; `author_name` se guarda siempre porque
  # es lo único que el JSON del panel de versiones sirve.
  # Example: ->(controller) { u = controller.current_user; [u, u.full_name] }
  mattr_accessor :content_versions_author, default: lambda { |controller|
    user = controller.try(:current_user)
    [ user, user.try(:name).presence || I18n.t("bali_view.content_versions.unknown_author") ]
  }

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
