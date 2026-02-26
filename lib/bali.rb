# frozen_string_literal: true

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

# Concerns
require "bali/concerns/controllers/device_variants"
require "bali/concerns/date_range_attribute"
require "bali/concerns/global_id_accessors"
require "bali/concerns/mailers/recipients_sanitizer"
require "bali/concerns/mailers/utm_params"
require "bali/concerns/numeric_attributes_with_commas"
require "bali/concerns/soft_delete"

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
require "bali/form_builder/password_fields"
require "bali/form_builder/percentage_fields"
require "bali/form_builder/radio_fields"
require "bali/form_builder/range_fields"
require "bali/form_builder/recurrent_event_rule_fields"
require "bali/form_builder/rich_text_area_fields"
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

# Commands
require "bali/commands/csv_export"
require "bali/commands/xlsx_export"

require "bali/form_builder"

require "bali/version"
require "bali/engine"

module Bali
  mattr_accessor :native_app, default: false
  mattr_accessor :custom_icons, default: {}
  mattr_accessor :ios_native_app_user_agent, default: /Turbo Native \(iOS\)/
  mattr_accessor :android_native_app_user_agent, default: /Turbo Native \(Android\)/
  mattr_accessor :sketchy_request_usernames, default: %w[admin cnadmin]

  # Deprecation alias for typo in original API
  DEPRECATOR = ActiveSupport::Deprecation.new("2.0", "Bali")
  private_constant :DEPRECATOR

  def self.sketcky_request_usernames
    DEPRECATOR.warn(
      "Bali.sketcky_request_usernames is deprecated. Use Bali.sketchy_request_usernames instead."
    )
    sketchy_request_usernames
  end

  def self.sketcky_request_usernames=(value)
    DEPRECATOR.warn(
      "Bali.sketcky_request_usernames= is deprecated. Use Bali.sketchy_request_usernames= instead."
    )
    self.sketchy_request_usernames = value
  end

  # Rich Text Editor configuration
  # Set to true to enable the Rich Text Editor component (requires TipTap dependencies)
  mattr_accessor :rich_text_editor_enabled, default: false

  # Block Editor configuration
  # Set to true to enable the Block Editor component (requires @blocknote/core)
  mattr_accessor :block_editor_enabled, default: false

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

  # Maximum upload file size in bytes. Default: 10.megabytes
  mattr_accessor :block_editor_max_upload_size, default: nil

  # Explicit upload URL path. When set, the component uses this instead of
  # auto-resolving from engine routes. Useful if you don't mount the engine.
  # Example: '/api/block_editor/uploads'
  mattr_accessor :block_editor_upload_url, default: nil

  def self.add_icon(name, svg_str)
    custom_icons[name.to_s] = svg_str
  end

  def self.config
    yield(self)
  end
end
