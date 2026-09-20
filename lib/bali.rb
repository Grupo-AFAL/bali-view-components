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

# Controller concerns. REQUIRED HERE, not autoloaded: the engine assigns an
# explicit `eager_load_paths` covering `app/` only, so anything under `lib/`
# resolves in a host solely because a line like this one loaded it. (The dummy
# app is not proof — it resolved this constant in development and raised
# NameError in test, which is the trap `engine.rb` warns about.)
require "bali/concerns/controllers/dashboard_widgets"

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

  # Whether passing a component's own slot name as a keyword raises (#1081). See
  # Bali::ApplicationViewComponent.new for what the keyword does when nothing stops it.
  #
  # Same posture as `raise_on_missing_translations`: loud where the author can still fix
  # it, a pass-through in production, where an exception would take down a page over a
  # heading that has already been missing since the deploy. Set it to `true` in production
  # if you would rather find out.
  mattr_writer :raise_on_slot_keyword_conflict, default: nil

  # Resolved per call rather than at load: this file is required while Bundler sets the
  # gems up, and `Rails.env` frozen there is the environment of whoever loaded first.
  def self.raise_on_slot_keyword_conflict
    return @@raise_on_slot_keyword_conflict unless @@raise_on_slot_keyword_conflict.nil?

    !Rails.env.production?
  end

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

  # Block Editor comments (#706) — default storage for threads/comments/reactions
  # (`bali_block_editor_*` tables, installed with
  # `bin/rails bali:install:migrations`). The three callables below are the WHOLE
  # configuration: without them the engine answers 404 to any request.
  #
  # Which host models a thread can hang off. A hash of
  # `"Document" => Document` (uses `.find_by(id:)`) or `"Document" => ->(id) { ... }`
  # to scope it by hand. The key is what `commentable_type` stores, that is
  # `record.class.polymorphic_name`.
  #
  # The EMPTY default is the security posture: mounting the engine enables
  # comments on nothing, and the type is never resolved through `constantize`.
  # An arity-2 lambda receives the CONTROLLER first (same shape as
  # `content_versionables`), which is what makes it possible to scope by user and
  # answer 404 for someone else's record instead of the authorize 403 (the 403/404
  # pair is an oracle).
  # Example: Bali.block_editor_commentables =
  #   { "Document" => ->(c, id) { c.current_user.documents.find_by(id: id) } }
  mattr_accessor :block_editor_commentables, default: {}

  # Author identity: callable evaluated with the controller, returns the userId
  # **string** (the JS contract is a string; the display name is resolved by the
  # client from `comments[:users]`/`users_url`). Same warning as saved_views: the
  # engine's controller does not inherit the host's — see docs/guides/engines.md.
  #
  # WATCH OUT: `RESTThreadStore` sends an `X-User-Id` header, and the engine
  # IGNORES it on purpose. It is informational; trusting it would let anyone
  # comment as anyone else.
  # Example: ->(controller) { controller.current_member&.id&.to_s }
  mattr_accessor :block_editor_comments_user,
                 default: ->(controller) { controller.try(:current_user)&.id&.to_s }

  # General access gate: callable (controller, user_id, commentable) — truthy
  # allows, falsy answers 403. This is the ENTRY permission; the per-action rules
  # (only the author edits their own comment, only the author of the first comment
  # deletes the thread) are wired into the controllers mirroring
  # `DefaultThreadStoreAuth`, which is what the UI already promises.
  # Example: ->(controller, user_id, commentable) { commentable.readable_by?(user_id) }
  mattr_accessor :block_editor_comments_authorize,
                 default: ->(_controller, user_id, _commentable) { user_id.present? }

  # Saved views (B2) — the default storage the engine ships (`bali_saved_views`
  # table, installed with `bin/rails bali:install:migrations`).
  #
  # Owner of the views: callable evaluated with the request's controller. WATCH OUT:
  # the ENGINE's controller does not inherit the host's ApplicationController, so a
  # `current_user` living in a host concern does not exist there on its own — either
  # the host teaches it (e.g. `Bali::SavedViewsController.include MyAuthConcern` in a
  # to_prepare, skipping the concern's before_action) or it configures this callable.
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

  # Bali::SavedViewsController authorization: callable (controller, owner) — truthy
  # allows, falsy answers 403. The default requires the owner to be present; an app can
  # harden it (e.g. Pundit) because the HOST's ApplicationController hooks do not apply
  # in the engine's controller.
  # Example: ->(controller, owner) { owner&.can?("tdflow.access") }
  mattr_accessor :saved_views_authorize, default: ->(_controller, owner) { owner.present? }

  # Entity references (#708) — ONE declaration per referenceable type, feeding the three
  # things that used to be declared separately: the `#` search, chip resolution and the
  # `references_config` the BlockEditor hands the JS.
  #
  # The key is at once the `entityType` that travels to the browser and the
  # `referenceable_type` stored in `bali_entity_references`, so it is the class name.
  #
  #   Bali.entity_reference_types = {
  #     "Document" => {
  #       search_scope:  -> { Document.published },      # what autocomplete offers
  #       lookup_scope:  -> { Document.all },            # INCLUDES archived: a broken chip
  #       search_fields: %i[title document_number],      #   is painted, not dropped
  #       display_field: :title,
  #       url:           ->(doc) { Rails.application.routes.url_helpers.document_path(doc) },
  #       unreachable?:  ->(doc) { doc.nil? || doc.archived? },
  #       extra_payload: ->(doc) { { entityCode: doc.number } },
  #       permission_scope: ->(controller, scope) { Pundit.policy_scope!(controller.current_user, scope) },
  #       display:       { icon: "▧", label: "Document", color: "success" }
  #     }
  #   }
  #
  # `url:` belongs to the host ON PURPOSE: the engine does not know the app's routes and
  # the resolver runs outside a view, where `main_app` does not exist. Only `search_scope`,
  # `lookup_scope`, `search_fields` and `display_field` are required. Full adoption guide:
  # docs/guides/engines.md.
  mattr_accessor :entity_reference_types, default: {}

  # Keys are normalized to String on assignment. They are at once the JSON's `entityType`
  # and the table's `referenceable_type`, and the registry is read from both sides:
  # declaring them with symbols left the controller resolving EVERYTHING as broken (it
  # compares against a String from params) while the model saw EVERYTHING as reachable,
  # with no error to give it away.
  def self.entity_reference_types=(types)
    @@entity_reference_types = types.to_h { |type, config| [ type.to_s, config ] } # rubocop:disable Style/ClassVars
  end

  # Bali::EntityReferencesController authorization: callable (controller) — truthy allows,
  # falsy answers 403. The default DENIES: the endpoints expose names of host records, so
  # they have to be opened by hand (and with a per-type `permission_scope:` for the rest).
  # Example: ->(controller) { controller.current_user.present? }
  mattr_accessor :entity_references_authorize, default: ->(_controller) { false }

  # The registry's `display:` sub-hash, ready for the BlockEditor's `references_config`.
  # The component uses it as the default when the host passes no `references_config:`, which
  # is what makes declaring a type enough for its chip to come out with its icon and color.
  def self.entity_references_config
    entity_reference_types.each_with_object({}) do |(type, config), out|
      display = config[:display]
      next if display.blank?

      out[type.to_s] = display.symbolize_keys.slice(:icon, :label, :color)
    end
  end

  # Reachability of a referent according to its type in the registry. An unregistered type
  # falls back to the default (present = reachable), which is what a panel listing old
  # references of a retired type wants.
  def self.entity_reference_unreachable?(type, record)
    gate = entity_reference_types.dig(type.to_s, :unreachable?)
    (gate || Bali::EntityReference::Resolver::DEFAULT_UNREACHABLE).call(record)
  end

  # Content versions (#707) — the document engine's polymorphic history
  # (`bali_content_versions` table, installed with `bin/rails bali:install:migrations`).
  #
  # Whitelist of versionable models `Bali::ContentVersionsController` accepts over
  # HTTP: `{ "Document" => ->(controller, id) { ... } }`. The key is the `record_type` that
  # travels in the query string (the model's `polymorphic_name`) and the value a callable
  # returning the record or nil. The `{}` default is DEFAULT-DENY: with no whitelist, any
  # `record_type` answers 404 — the only way to expose a model is to name it here.
  #
  # The resolver is where the scoping belongs: returning only what that user can see
  # (`controller.current_user.documents.find_by(id: id)`) makes someone else's record a 404
  # instead of a 403 that confirms it exists.
  # Example: Bali.content_versionables = {
  #   "Document" => ->(controller, id) { controller.current_user.documents.find_by(id: id) }
  # }
  mattr_accessor :content_versionables, default: {}

  # Bali::ContentVersionsController authorization: callable (controller, record, action)
  # — truthy allows, falsy answers 403. The default DENIES everything: reading the history
  # of a host model is the host's decision, and its ApplicationController hooks do not
  # apply in the engine's controller. `action` is "index", "show" or "restore", so reading
  # can be left open to everyone and restoring to only a few.
  # Example: ->(controller, record, action) { action == "restore" ? record.editable_by?(controller.current_user) : true }
  mattr_accessor :content_versions_authorize, default: ->(_controller, _record, _action) { false }

  # Author of the versions the engine CREATES (today only the restore's): callable
  # (controller) returning `[author, author_name]`. `author` is optional —a host with no
  # user model returns nil and only names—; `author_name` is always stored because it is
  # the only thing the versions panel's JSON serves.
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
